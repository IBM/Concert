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

const airportsList = require('../data/airports_list.json');

const utils = require('../utils');

const router = express.Router();

/* GET airport listing. */
router.get('/', (req, res) => {
    const search_query = req.query.q;
    let results;
    if(!search_query) {
        // fetch all airports
        results = airportsList.filter(elem => elem.icao);
        // add pagination layer
        let page = 1, per_page = 100;
        if(req.query.page && !isNaN(req.query.page) && parseInt(req.query.page) > 0) {
            page = parseInt(req.query.page);
        }
        if(req.query.per_page && !isNaN(req.query.per_page) && parseInt(req.query.per_page) > 0) {
            per_page = parseInt(req.query.per_page);
        }
        results = utils.paginate(results, per_page, page);
        results = utils.prepareResults(results, utils.addMetaToAirportInfo);
        return res.status(!utils.isEmptyList(results) ? 200 : 404).send({
            status: true,
            data: !utils.isEmptyList(results) ? results.filter(elem => elem.code) : [],
            page,
            per_page
        });
    }
    results = airportsList.filter(elem => elem.icao).filter((elem) => {
        return elem.name.toLowerCase().includes(search_query.toLowerCase()) ||
            elem.city.toLowerCase().includes(search_query.toLowerCase()) ||
            elem.code.toLowerCase().includes(search_query.toLowerCase()) ||
            elem.icao.toLowerCase().includes(search_query.toLowerCase());
    });
    results = utils.prepareResults(results, utils.addMetaToAirportInfo);
    return res.status(!utils.isEmptyList(results) ? 200 : 404).send({
        data: !utils.isEmptyList(results) ? results : [],
        status: !utils.isEmptyList(results)
    });
});

module.exports = router;
