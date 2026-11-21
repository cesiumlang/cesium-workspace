"""Keeps the Cesium Roadmap Project (cesiumlang, project 1) in order.

Run with the Cesium Agent's token in GH_TOKEN:
  GH_TOKEN="$(bash /c/scratch/github-apps/app-token.sh cesiumlang)" python -I project.py <command> ...

Commands:
  list [TRACK]                       rows in priority order: position, status, track, item, title
  add REF TRACK (--after REF | --top) add an issue (or move it) with that Track, placed after REF
  move REF (--after REF | --top)     place an existing row
  status STATUS REF...               set Status (Todo, In Progress, Done)
  track TRACK REF...                 set Track
  block BLOCKED BLOCKER...           link "BLOCKED is blocked by BLOCKER" between issues
  draft TITLE BODY TRACK (--after REF | --top)   add a draft item for a plan without an issue

REF is repo#number in cesiumlang, e.g. cesium#57 or vscode-cesium#7 (".github" for the org repo).
"""
import json
import subprocess
import sys

ORG = "cesiumlang"
NUMBER = 1


def run(args, stdin=None):
    r = subprocess.run(args, input=stdin, capture_output=True, text=True, encoding="utf-8")
    return r.returncode, r.stdout, r.stderr


def gql(query, **variables):
    args = ["gh", "api", "graphql", "-f", "query=" + query]
    for key, value in variables.items():
        args += ["-F" if isinstance(value, int) else "-f", f"{key}={value}"]
    code, out, err = run(args)
    data = json.loads(out or "{}")
    if code or data.get("errors"):
        sys.exit(f"GraphQL error: {out}{err}")
    return data["data"]


def project():
    q = """query($o:String!,$n:Int!){organization(login:$o){projectV2(number:$n){id
      fields(first:30){nodes{... on ProjectV2SingleSelectField{id name options{id name}}}}}}}"""
    p = gql(q, o=ORG, n=NUMBER)["organization"]["projectV2"]
    fields = {f["name"]: f for f in p["fields"]["nodes"] if f}
    return p["id"], fields


def option(fields, name, value):
    options = {o["name"]: o["id"] for o in fields[name]["options"]}
    if value not in options:
        sys.exit(f"{name} has no option {value!r}; options: {', '.join(options)}")
    return fields[name]["id"], options[value]


def split_ref(ref):
    repo, _, num = ref.partition("#")
    if not repo or not num.isdigit():
        sys.exit(f"not a reference: {ref!r} (expected repo#number)")
    return repo, int(num)


def issue_node(ref):
    repo, num = split_ref(ref)
    q = """query($o:String!,$r:String!,$n:Int!){repository(owner:$o,name:$r){
      issueOrPullRequest(number:$n){... on Issue{id projectItems(first:10){nodes{id project{number}}}}
                                    ... on PullRequest{id projectItems(first:10){nodes{id project{number}}}}}}}"""
    node = gql(q, o=ORG, r=repo, n=num)["repository"]["issueOrPullRequest"]
    if node is None:
        sys.exit(f"{ref} does not exist")
    items = [i["id"] for i in node["projectItems"]["nodes"] if i["project"]["number"] == NUMBER]
    return node["id"], (items[0] if items else None)


def item_of(ref):
    _, item = issue_node(ref)
    if item is None:
        sys.exit(f"{ref} is not on the Project")
    return item


def set_field(pid, item, field_id, option_id):
    q = """mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){updateProjectV2ItemFieldValue(
      input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){projectV2Item{id}}}"""
    gql(q, p=pid, i=item, f=field_id, o=option_id)


def place(pid, item, after_ref):
    if after_ref is None:
        q = """mutation($p:ID!,$i:ID!){updateProjectV2ItemPosition(input:{projectId:$p,itemId:$i}){
          items(first:1){totalCount}}}"""
        gql(q, p=pid, i=item)
    else:
        q = """mutation($p:ID!,$i:ID!,$a:ID!){updateProjectV2ItemPosition(input:{projectId:$p,itemId:$i,afterId:$a}){
          items(first:1){totalCount}}}"""
        gql(q, p=pid, i=item, a=item_of(after_ref))


def where(args):
    if "--top" in args:
        return None
    if "--after" in args and args.index("--after") + 1 < len(args):
        return args[args.index("--after") + 1]
    sys.exit("give --after REF or --top")


def cmd_list(args):
    q = """query($o:String!,$n:Int!,$c:String){organization(login:$o){projectV2(number:$n){
      items(first:100,after:$c){pageInfo{hasNextPage endCursor} nodes{
        fieldValues(first:10){nodes{... on ProjectV2ItemFieldSingleSelectValue{name field{... on ProjectV2SingleSelectField{name}}}}}
        content{... on Issue{number title repository{name}} ... on PullRequest{number title repository{name}}
                ... on DraftIssue{title}}}}}}}"""
    rows, cursor = [], None
    while True:
        variables = dict(o=ORG, n=NUMBER)
        if cursor:
            variables["c"] = cursor
        page = gql(q, **variables)["organization"]["projectV2"]["items"]
        rows += page["nodes"]
        if not page["pageInfo"]["hasNextPage"]:
            break
        cursor = page["pageInfo"]["endCursor"]
    for pos, row in enumerate(rows, 1):
        values = {v["field"]["name"]: v["name"] for v in row["fieldValues"]["nodes"] if v}
        track = values.get("Track", "")
        if args and track != args[0]:
            continue
        c = row["content"] or {}
        ref = f"{c['repository']['name']}#{c['number']}" if "number" in c else "draft"
        print(f"{pos:3} {values.get('Status', ''):11} {track:26} {ref:24} {c.get('title', '')}")


def cmd_add(args):
    if len(args) < 2:
        sys.exit("add REF TRACK (--after REF | --top)")
    pid, fields = project()
    content, item = issue_node(args[0])
    if item is None:
        q = "mutation($p:ID!,$c:ID!){addProjectV2ItemById(input:{projectId:$p,contentId:$c}){item{id}}}"
        item = gql(q, p=pid, c=content)["addProjectV2ItemById"]["item"]["id"]
        set_field(pid, item, *option(fields, "Status", "Todo"))
    set_field(pid, item, *option(fields, "Track", args[1]))
    place(pid, item, where(args))
    print(f"{args[0]}: {args[1]}, placed")


def cmd_move(args):
    pid, _ = project()
    place(pid, item_of(args[0]), where(args))
    print(f"{args[0]}: placed")


def cmd_field(name, args):
    pid, fields = project()
    field_id, option_id = option(fields, name, args[0])
    for ref in args[1:]:
        set_field(pid, item_of(ref), field_id, option_id)
        print(f"{ref}: {name} {args[0]}")


def cmd_block(args):
    blocked = args[0]
    for blocker in args[1:]:
        repo, num = split_ref(blocker)
        code, out, err = run(["gh", "api", f"repos/{ORG}/{repo}/issues/{num}", "-q", ".id"])
        if code:
            sys.exit(err)
        blocked_repo, blocked_num = split_ref(blocked)
        code, out, err = run(["gh", "api", "-X", "POST",
                              f"repos/{ORG}/{blocked_repo}/issues/{blocked_num}/dependencies/blocked_by",
                              "-F", f"issue_id={out.strip()}"])
        print(f"{blocked} blocked by {blocker}: {'ok' if code == 0 else err.strip()}")


def cmd_draft(args):
    if len(args) < 3:
        sys.exit("draft TITLE BODY TRACK (--after REF | --top)")
    pid, fields = project()
    q = """mutation($p:ID!,$t:String!,$b:String!){addProjectV2DraftIssue(input:{projectId:$p,title:$t,body:$b}){
      projectItem{id}}}"""
    item = gql(q, p=pid, t=args[0], b=args[1])["addProjectV2DraftIssue"]["projectItem"]["id"]
    set_field(pid, item, *option(fields, "Status", "Todo"))
    set_field(pid, item, *option(fields, "Track", args[2]))
    place(pid, item, where(args))
    print(f"draft {args[0]!r}: {args[2]}, placed")


def main(argv):
    if not argv:
        sys.exit(__doc__)
    command, args = argv[0], argv[1:]
    commands = {"list": cmd_list, "add": cmd_add, "move": cmd_move, "block": cmd_block, "draft": cmd_draft,
                "status": lambda a: cmd_field("Status", a), "track": lambda a: cmd_field("Track", a)}
    if command not in commands:
        sys.exit(__doc__)
    commands[command](args)


if __name__ == "__main__":
    main(sys.argv[1:])
