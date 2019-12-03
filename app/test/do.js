const { exec } = require('child_process');

    const soql = 'sfdx force:data:soql:query -q "select id from rb__c" -u "murakoshi@cse.co.jp" --json';
    const cmd = 'sfdx force:apex:execute -f "a.txt" -u "murakoshi@cse.co.jp" --json';

    module.exports = {
      do: function(res, clb) {
        exec(soql, (error, stdout, stderr) => {
            if (error) {
                console.error(`[ERROR] ${error}`);
                return;
            }else{
                return clb(res, stdout);
            }
        });
      },

      apex: function(res, clb){
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                console.error(`[ERROR] ${error}`);
                return;
            }else{
                return clb(res, stdout);
            }
        });
      }
    };
