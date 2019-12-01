const { exec } = require('child_process');

  const cmd = 'sfdx force:data:soql:query -q "select id from rb__c" -u "murakoshi@cse.co.jp" --json';

    function ttr(res){
        console.log(123);
        console.log(res);
        return res;
    }

    module.exports = {
      do: function(clb) {
        exec(cmd, (error, stdout, stderr) => {
            if (error) {
                console.error(`[ERROR] ${error}`);
                return;
            }else{
                return clb(stdout);
            }
        });
      }
    };