# OpenLDAP-Dockerfile
安装 OpenLDAP 是一件麻烦的事情，所以写了一个Dockerfile

1. git clone 仓库的文件
2. 使用Dockerfile构建Image
```shell
docker build -t ~/ldap .
```
3. 启动容器
```shell
# ROOT 管理员账号
# LDAP_PWD 管理员密码
# DC dc

docker run -d --name ldap -p 389:389 -p 636:636 -e ROOT=admin -e LDAP_PWD=123 -e DC=dc=lindafeng,dc=com  ldf/ldap
```
