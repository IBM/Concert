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

const express = require('express');

const csrfProtection = require('../utils/csrf-middleware');

const router = express.Router();

function logincheck(req, _res, next) {
  if (req.session && req.session.userEmail) {
    req.isLoggedInUser = true
  } else {
    req.isLoggedInUser = false
  }
  next();
}

router.get('/health', (_req, res) => {
  return res.status(200).json({health:"OK"})
})

/* GET home page. */
router.get('/', logincheck, csrfProtection, (req, res) => {
  res.render('index', { isLoggedInUser: req.isLoggedInUser, userEmail: req.session.userEmail, _csrf: req.csrfToken() });
});

/* Login code */
router.post('/', (req, res, next) => {
  if (req.body.username && req.body.password) {
    req.session.userEmail = req.body.username;
    return res.redirect('/');
  } else {
    let err = new Error('All fields required.');
    err.status = 400;
    return next(err);
  }
})

/* Logout code */
router.get('/logout', (req, res, next) => {
  if (req.session) {
    req.session.destroy((err) => {
      if (err) {
        return next(err);
      }
      return res.redirect('/');
    });
  }
});

module.exports = router;
