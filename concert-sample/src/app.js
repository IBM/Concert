/*
 *  Copyright IBM Corp. 2021.
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
 * an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations under the License.
 */
const createError = require('http-errors');
const express = require('express');
const path = require('path');
const cookieParser = require('cookie-parser');
const session = require('express-session');
const helmet = require('helmet');
const nocache = require("nocache");
const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const BearerStrategy = require('passport-http-bearer').Strategy;
const BasicStrategy = require('passport-http').BasicStrategy;

passport.serializeUser(function(user, done) {
  done(null, user.id);
});

passport.deserializeUser(function(_id, done) {
  done({
    id: 1, 
    name: "User1"
  });
});

passport.use(new LocalStrategy((username, password, done) => {
  return handleLocalandBasicStrategy(username, password, "Username / password mismatch", done );
}));

passport.use(new BearerStrategy((token, done) => {
    if(token) {
      return done(null, { id: 1, name: "User1" });
    }
    return done({ message: "Token mismatch" });
  }
));

passport.use(new BasicStrategy((username, password, done) => {
    return handleLocalandBasicStrategy(username, password, "Username / password mismatch", done );
  }
));

function handleLocalandBasicStrategy(username, password, message, done) {
  if (username && password) {
    return done(null, { id: 1, name: "User1" });
  }
  return done({ message });
}

const indexRouter = require('./routes/index');
const flightBookingRouter = require('./routes/flights');
const airportsRouter = require('./routes/airports');
const authRouter = require('./routes/auth');

const defaultDirectives = helmet.contentSecurityPolicy.getDefaultDirectives();
delete defaultDirectives['upgrade-insecure-requests'];
delete defaultDirectives['block-all-mixed-content'];

const app = express();
app.use(helmet.hidePoweredBy());
app.use(helmet.frameguard());
app.use(helmet.noSniff());
app.use(nocache());
app.use(
  helmet.contentSecurityPolicy({
    directives: {
      ...defaultDirectives,
      "script-src": ["'self'"],
      "style-src": ["'self'"],
      "font-src": ["'self'", "fonts.gstatic.com"],
      "form-action": ["'self'"]
    },
  })
);

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

app.use(session({ secret: 'work hard', saveUninitialized: true, resave: true, cookie : { httpOnly: true, sameSite: 'strict', secure: true } }));
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, 'public')));
app.use(passport.initialize());
app.use(passport.session());

app.use('/flightbooking', flightBookingRouter);
app.use('/airports', airportsRouter);
app.use('/auth', authenticate, authRouter);
app.use('/', indexRouter);

// catch 404 and forward to error handler
app.use((_req, _res, next) => {
  next(createError(404));
});

// error handler
app.use((err, req, res, _next) => {
  // set locals, only providing error in development
  console.log(err);
  res.locals.message = err.message;
  res.locals.error = req.app.get('env') === 'development' ? err : {};

  res.status(err.status || 500).send({
    message: err.message
  });
});

function authenticate (req, res, next){
  passport.authenticate(['local', 'bearer', 'basic'], function(err, user) { 
      if (err) { 
        return res.status(401).send(err) 
      } 
      if (!user) { 
        return res.status(401).send({
          "message": "Please check your authorization credentials"
        }); 
      } 
      req.user = user;
      next();
  })(req, res, next);
}

module.exports = app;
