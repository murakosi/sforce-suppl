    const url = require('url');
    const fs = require('fs');
    const do1 = require("./do.js");
    
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
                  do1.do(function(ret){
                    response.writeHead(200, {'Content-Type': 'text/json'});
                    response.write(ret);
                    response.end();
                  });
                  break;
              default:
                  response.writeHead(404);
                  response.write('Route not defined');
                  response.end();
          }
      }
    };