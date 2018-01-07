function isDockerInstalled(){
    echo "[INFO] Check docker installation"
    check_docker_results="`docker -v`"
    if [[ $check_docker_results =~ "Docker" ]];then 
    return 1
    else
    return 0
    fi
}
function isGitInstalled(){
    echo "[INFO] Check git installation"
    check_git_results="`git --version`"
    if [[ $check_git_results =~ "git" ]];then 
    return 1
    else
    return 0
    fi
}
function ensureEnv(){
    isDockerInstalled
    hasDocker=$?
    if [[ $hasDocker -eq 0 ]];then
    echo "[INFO] Start docker-ce installation"
    fi
    
    isGitInstalled
    hasGit=$?
    if [[ $hasGit -eq 0 ]];then
    echo "[INFO] Start git installation"
    fi
}
function ensureHostPort(){
    echo "[INFO] Open host port: $hostPort for your java web application."
    `systemctl start firewalld`
    `systemctl enable firewalld`
    `firewall-cmd --zone=public --add-port=$hostPort/tcp --permanent`
    `firewall-cmd --reload`
}
function installDocker(){
    sudo yum install -y yum-utils
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum makecache fast
    sudo yum install docker-ce
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo docker info
}
function startJavaWebDev(){
    echo "[INFO] Run maven3 container to create sample project."
    workspace="maven-workspace"
    projectRepoPath="$workspace-repo"
    mkdir "$projectName" "$projectRepoPath"
    `docker run -it --rm --name $workspace -v "$PWD"/$workspace:/usr/src/$workspace -v "$PWD"/$projectRepoPath/:/root/.m2/repository -w /usr/src/$workspace maven:3 mvn -B archetype:generate -DgroupId=maven-test -DartifactId=$projectName -DarchetypeArtifactId=maven-archetype-webapp`
    echo "[INFO] Use tomcat8 container to run your application"
    `docker run --name $projectName -d -p $hostPort:8080 -v "$PWD"/$workspace/$projectName/src/main/webapp/:/usr/local/tomcat/webapps/$projectName/ tomcat:8`
}
function main(){
    if [ ! -z $1 ];then
    projectName="$1"
    else
    projectName="maven-hello-world"
    fi
    
    if [ ! -z $2 ];then
    gitUrl="$2"
    fi
    
    if [ ! -z $3 ];then
    hostPort="$3"
    else
    hostPort=8080
    fi
    
    echo "$hostPort"    
    ensureEnv
    ensureHostPort hostPort
    startJavaWebDev projectName gitUrl hostPort
    echo "[INFO] Succeeded."
    echo "[INFO] Use $ curl localhost:$hostPort/$projectName/ to verify."
}

main $1 $2 $3
