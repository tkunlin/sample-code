How to deploy this package?

Run the command as below to extract tarball and deploy package
# tar xzvf billing-tool-db-export-$VERSION.tar.gz /tmp/billing-tool-db-export-$VERSION
# cd /tmp/billing-tool-db-export-$VERSION
# chmod +x deploy.sh 
# ./deploy.sh db_backup_v1.1.0.0 (folder name)
or 
# ./deploy.sh ecv (For ecv db export)
# ./deploy.sh ecr (For ecr db export)



Release notes:

2024-01-16
  Issuses Fixed:
    n/a
   

  Improvement:
    * Added new tables for daily backup

  Feature:
    n/a
  

2023-12-07

  Issuses Fixed:
    n/a
   

  Improvement:
    * Force de-identification in Dev environment.
    * DB-export: In ECV-Prod DB use replicate db endpoint,
                 In ECR-Prod DB use master db endpoint.

  Feature:
    DB-restore
    * Support auto delete scripts after restore data into database.
    * Added new flags
      --permission   allow / dis-allow added mgt permissions into database.
      --poweroff     poweroff ec2 after restoring database.
      