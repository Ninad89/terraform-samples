#!/bin/bash

sudo yum install -y amazon-efs-utils
sudo mkdir /efs
sudo mount -t efs -o tls fs-40da82b1: /efs
sudo mkdir -p /efs/jenkins/builds


sudo yum install java-1.8.0-openjdk-devel -y
wget http://mirrors.jenkins.io/war-stable/latest/jenkins.war

# export JENKINS_HOME=/efs/jenkins
sudo nohup java -jar -Djenkins.install.runSetupWizard=false -Djenkins.model.Jenkins.buildsDir=/efs/jenkins/builds/\${ITEM_FULL_NAME} \
jenkins.war --argumentsRealm.passwd.ninad=123 --argumentsRealm.roles.ninad=admin &

while netstat -lnt | awk '$4 ~ /:8080$/ {exit 1}'; do echo waiting..; sleep 10; done

sleep 20;

wget http://localhost:8080/jnlpJars/jenkins-cli.jar

echo "<?xml version='1.1' encoding='UTF-8'?> \
<project> \
  <description></description> \
  <keepDependencies>false</keepDependencies> \
  <properties/>\
  <scm class='hudson.scm.NullSCM'/>\
  <canRoam>true</canRoam>\
  <disabled>false</disabled>\
  <blockBuildWhenDownstreamBuilding>false</blockBuildWhenDownstreamBuilding>\
  <blockBuildWhenUpstreamBuilding>false</blockBuildWhenUpstreamBuilding>\
  <triggers/>\
  <concurrentBuild>false</concurrentBuild>\
  <builders>\
    <hudson.tasks.Shell>\
      <command>echo Hello</command>\
      <configuredLocalRules/>\
    </hudson.tasks.Shell>\
  </builders>\
  <publishers/>\
  <buildWrappers/>\
</project>" | java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket create-job testJob

sudo sed -i 's/AuthorizationStrategy$Unsecured/LegacyAuthorizationStrategy/' /root/.jenkins/config.xml
sudo sed -i 's/SecurityRealm$None/LegacySecurityRealm/' /root/.jenkins/config.xml
sudo java -jar jenkins-cli.jar -s http://localhost:8080/ -webSocket reload-configuration


