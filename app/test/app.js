    const url = require('url');
    const fs = require('fs');
    const do1 = require("./do.js");
    const Log_split_char = "|"
    const Log_split_limit = 3
    const Log_headers = ["Timestamp", "Event", "Details"]

    function renderHTML(path, response) {
        fs.readFile(path, null, function(error, data) {
            if (error) {
                response.writeHead(404);
                response.write('File does not exists!');
            } else {
                response.write(data);
            }
            response.end();
        });
    }

    function parseQueryResult(response, result){
            response.writeHead(200, {'Content-Type': 'text/json'});
            response.write(result);
            response.end();      
    }

    function parseApexResult(response, res){
        var logs = JSON.parse(res).result.logs.split("\n").map(str => str.split(Log_split_char, Log_split_limit));
        logs.filter(log => log.length >= 1).map(log => fill_blank(log));
        response.writeHead(200, {'Content-Type': 'application/json'});
        response.write(JSON.stringify({logs:logs}));
        response.end();
    }

    function fill_blank(log){
        if(log.length == 1){
            return ["","",log[0]];
        }else if(log.length == 2){
            return [log[0],log[1],""];
        }else{
            return log;
        }
    }

    module.exports = {
      handleRequest: function(request, response) {
          response.writeHead(200, {'Content-Type': 'text/html'});
          const path = url.parse(request.url).pathname;
          switch (path) {
              case '/':
                  renderHTML('./main.html', response);
                  break;
              case '/logout':
                  renderHTML('./login.html', response);
                  break;
              case '/abc':
                    do1.do(response, parseQueryResult);
                  break;
              case '/apex':
                    do1.apex(response, parseApexResult);
                  break;
              default:
                  response.writeHead(404);
                  response.write('Route not defined');
                  response.end();
          }
      }
    };