#!/bin/bash

/bin/mysqlcheck --user maintenance --all-databases --auto-repair --check-only-changed --optimize --silent
