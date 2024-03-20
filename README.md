# Gitlab CE IaC preset

- gitlab-ce server `16.9.1-ce.0`
- gitlab build runner `alpine3.18-v16.9.1 shell + custom DinD`
- gitlab test runner `alpine3.18-v16.9.1 shell + custom DinD`
- gitlab deploy runner `alpine3.18-v16.9.1 shell + custom DinD`

# How to

- copy repo
- execute `./deploy.sh` script

# Postinstall steps

- change `root` password
- enjoy
