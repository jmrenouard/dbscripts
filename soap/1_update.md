# Standard Operations: Update System

## Table of contents
- [Main document target](#main-document-target)
- [Main update Procedure for Red Hat Family OS](#main-update-procedure-for-red-hat-family-os)
- [Update Procedure example for Red Hat Family OS](#update-procedure-example-for-red-hat-family-os)


## Main document target

> Update system packages to insure hight security level


## Main update Procedure for Red Hat Family OS
| Step | Description | User | Command |
| --- | --- | --- | --- |
| 1 | Update package information | root | # yum clean all |
| 2 | Download and install all new package avalaible | root | # yum -y update |


##  Update Procedure example for Red Hat Family OS
```
# yum clean all

# yum -y update
```
