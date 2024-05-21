# Microsoft SQL tools for Ansible

This collection contains several roles for configuring and maintaining MS SQL.

## Requirements

An Execution Environment with the required collections/libraries can be found [here](https://quay.io/repository/rh_ee_baddicks/mssql).

## Role - ssms

Simple role to install SSMS. Currently just grabs the latest version, might add different version at a later date.

### Example

```yaml
- name: Install SQL Server on Window host
  hosts: mssqlservers
  gather_facts: false

  tasks:
    - name: Install SSMS
      ansible.builtin.include_role:
        name: brianaddicks.mssql_tools.ssms
```

## Role - enable_cluster

Configure SQL Always on Cluster. Currently only support file share quorum. Can be broken up into the follow stages with tags.

^ tag ^ description ^
| win_firewall | Configures windows firewall to allow traffic between nodes |
| create_quorum_share | Creates directory/share for quorum witness |
| failover_cluster | configured Windows Failover Clustering |
| sql_always_on | Create SQL Always On AG |
| add_databases | Creates databases and adds them to AG |

### Roles Variables

^ Variable ^ Default ^ Value or Expression ^
| mssql_agentsvc_account_pass | ❌ | REQUIRED |
| mssql_agentsvc_account | ❌ | REQUIRED |
| mssql_assvc_account_pass | ❌ | REQUIRED |
| mssql_assvc_account | ❌ | REQUIRED |
| mssql_sqlsvc_account_pass | ❌ | REQUIRED |
| mssql_sqlsvc_account | ❌ | REQUIRED |
| mssql_ag_name | ❌ | TestAG |
| mssql_backup_path | ❌ | "c:\\sqlbackup" |
| mssql_base_ldap_path | ❌ | 'OU=Users,DC=example,DC=com' |
| mssql_cluster_name | ❌ | SqlCluster |
| mssql_computer_ou | ❌ | OU=Computers,DC=example,DC=com |
| mssql_database_names | ❌ | [TestDB] |
| mssql_domain_controller | ❌ | dc1.example.com |
| mssql_failover_cluster_ip | ❌ | 192.0.2.1/24 |
| mssql_file_quorum_hostname | ❌ | witness.example.com |
| mssql_file_quorum_path | ❌ | "c:\\quorum" |
| mssql_file_quorum_path | ❌ | "c:\\quorum" |
| mssql_file_quorum_share_name | ❌ | quorum |
| mssql_instance_name | ❌ | MSSQLSERVER |
| mssql_listener_ip | ❌ | 192.0.2.10/255.255.255.0 |
| mssql_listener_port | ❌ | 5301 |
| mssql_netbios | ❌ | EXAMPLE |
| mssql_restore_path | ❌ | "\\\\test-mssql1\\sqlbackup" |
| mssql_share_name | ❌ | quorum |
| mssql_share_name | ❌ | sqlbackup |
| mssql_temp_download_path | ❌ | "c:\\tmp" |

### Example

```yaml
- name: Enable Cluster with file quorum node
  ansible.builtin.include_role:
    name: brianaddicks.mssql_tools.enable_cluster
```
