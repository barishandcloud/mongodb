#!/bin/bash

mongosh <<EOF
var config = {
    "_id": "dbrs",
    "version": 1,
    "members": [
        {
            "_id": 1,
            "host": "mongo_con1.1.nad5zxxup3127x94ei3aae39k:27017",
            "priority": 3
        },
        {
            "_id": 2,
            "host": "mongo_con2.1.sbr18kpwwpmj78lggr2pt2821:27017",
            "priority": 2
        },
        {
            "_id": 3,
            "host": "mongo_con3.1.7tf3yf7gpymfrannter5iqnod:27017",
            "priority": 1
        }
    ]
};
rs.initiate(config, { force: true });
rs.status();
EOF