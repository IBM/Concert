const csrf = require('csurf');

const csrfProtection = csrf({ 
    cookie: {
        httpOnly: true,
        sameSite: 'strict',
        secure: true        
    },
 });

module.exports = csrfProtection;
