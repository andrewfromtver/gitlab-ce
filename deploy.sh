#!/bin/sh

echo "################### Build & deploy Gitlab-CE ##################"
docker compose down
docker volume rm gitlab-ce_build_runner_conf gitlab-ce_deploy_runner_conf gitlab-ce_test_runner_conf 2>/dev/null
docker compose -p gitlab-ce up -d --build --wait gitlab-ce
echo "###############################################################"

echo "..."

echo "#################### Check Gitlab-CE state ####################"
docker compose -p gitlab-ce ps
echo "###############################################################"

echo "..."

echo "############## Gitlab runner registration token ###############"
RUNNER_REG_TOKEN=$(docker exec -it gitlab-ce gitlab-rails runner -e production 'puts Gitlab::CurrentSettings.current_application_settings.runners_registration_token')
echo "Token: $RUNNER_REG_TOKEN"
echo "###############################################################"

echo "..."

echo "################ Gitlab initial root password #################"
docker exec -it gitlab-ce bash -c 'grep 'Password:' /etc/gitlab/initial_root_password 2>/dev/null || echo "Custom root password already exists."'
echo "###############################################################"

echo "..."

echo "################# Base runners registration ###################"
echo "Registering  gitlab-build-runner ..."
./reg_new_runner.sh gitlab-build-runner build $RUNNER_REG_TOKEN "gitlab.vm"
echo "Registering  gitlab-test-runner ..."
./reg_new_runner.sh gitlab-test-runner test $RUNNER_REG_TOKEN "gitlab.vm"
echo "Registering  gitlab-deploy-runner ..."
./reg_new_runner.sh gitlab-deploy-runner deploy $RUNNER_REG_TOKEN "gitlab.vm"
echo "###############################################################"
