#!/bin/bash


/bin/mysqlcheck --user=maintenance --all-databases --check-only-changed --silent
/bin/mysqlcheck --user=maintenance --all-databases --auto-repair --silent
#/bin/mysqlcheck --user=maintenance --all-databases --analyze --silent
#/bin/mysqlcheck --user=maintenance --all-databases --optimize --silent
