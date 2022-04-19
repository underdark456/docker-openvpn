#!/bin/bash

: ${1?' Please, specify client name'}

source ./functions.sh

createConfig $1