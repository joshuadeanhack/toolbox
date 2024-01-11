## Python Script to Inject JSON Key Value

`inject_json.py --file <filepath> --modify <Key> <Value> --modify <keyN> <value n>`

e.g.

`inject_json.py --file %teamcity.checkout.dir%/Engine/Build/Build.version --modify Changelist %build.vcs.number%`
