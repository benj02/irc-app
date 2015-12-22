# Boeing Coupon Program Form

This program let's you easily modify the GCode file running the N64, calculate your boxes, get assistance and basically accelerates the whole production process.

## Getting started

You'll a few global utils, install them like so

    $ npm install -g coffee-script gulp-cli nodemon

## Running the server

1) In development:

    $ gulp
    $ nodemon

2) In Production (on windows):

    C:\...> install-service.bat
    [Set the service to run as user]
    C:\...> net start "coupon-form"

Once the server is running, open it at 'http://[server ip]:3000/'.
