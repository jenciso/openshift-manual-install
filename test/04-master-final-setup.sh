#!/bin/bash

oadm manage-node ose3-master.example.com --schedulable=false
oadm manage-node ose3-node1.example.com --schedulable=true

oc label --overwrite node ose3-master.example.com region=infra zone=default
oc label --overwrite node ose3-node1.example.com region=primary zone=east
