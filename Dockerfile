FROM centos:7

# 环境变量
ENV ROOT="admin"
ENV LDAP_PWD="v5bep7"
ENV DC="dc=lindafeng,dc=com"

# 安装
RUN \
    yum install -y openldap openldap-clients openldap-servers && \
    cp /usr/share/openldap-servers/DB_CONFIG.example /var/lib/ldap/DB_CONFIG && \
    chown ldap:ldap -R /var/lib/ldap && \
    chmod 700 -R /var/lib/ldap

VOLUME /data
RUN mkdir -p /data/ldap
COPY . /data/ldap
WORKDIR ~

# 启动
RUN \
    cd /usr/sbin && \
    ./slapd -u ldap -h "ldap:/// ldapi:///" && \
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/cosine.ldif && \
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/nis.ldif && \
    ldapadd -Y EXTERNAL -H ldapi:/// -f /etc/openldap/schema/inetorgperson.ldif && \
    cd /data/ldap && \
    PWD=$(slappasswd -s ${LDAP_PWD}) && \
    echo "olcRootPW: $PWD" >> passwd.txt && \
    cat passwd.txt >> 1_hdb_passwd.ldif && \
    ldapmodify -Y EXTERNAL -H ldapi:/// -f 1_hdb_passwd.ldif && \
    sed -i "s/dc=lindafeng,dc=com/${DC}/g" 2_change_domain.ldif && \
    sed -i "s/cn=admin/cn=${ROOT}/g" 2_change_domain.ldif && \
    ldapmodify -Y EXTERNAL -H ldapi:/// -f 2_change_domain.ldif && \
    sed -i "s/dc=lindafeng,dc=com/${DC}/g" 3_load_data.ldif && \
    sed -i "s/cn=admin/cn=${ROOT}/g" 3_load_data.ldif && \
    ldapadd -x -w ${LDAP_PWD} -D "cn=${ROOT},${DC}" -f 3_load_data.ldif &&\
    cat passwd.txt >> 4_config_pwd.ldif && \
    ldapmodify -Y EXTERNAL -H ldapi:/// -f 4_config_pwd.ldif && \
    rm -rf passwd.txt && \
    sed -i "s/dc=lindafeng,dc=com/${DC}/g" 5.change_access.ldif && \
    sed -i "s/cn=admin/cn=${ROOT}/g" 5.change_access.ldif && \
    ldapadd -Y EXTERNAL -H ldapi:/// -f 5.change_access.ldif && \
    ldapadd -Q -Y EXTERNAL -H ldapi:/// -f 6_use_memberof.ldif && \
    ldapmodify -Q -Y EXTERNAL -H ldapi:/// -f 7_refint1.ldif && \
    ldapadd -Q -Y EXTERNAL -H ldapi:/// -f 8_refint2.ldif && \
    OUTPUT=$(pgrep slapd) && kill $OUTPUT && \
    cd ~

EXPOSE 389
EXPOSE 636

CMD ["sh","-c","/usr/sbin/slapd -d256 -u ldap -h 'ldap:/// ldapi:///'"]
