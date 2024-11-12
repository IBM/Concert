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
const helmet = require('helmet');

const router = express.Router();
router.use(helmet.frameguard({ action: 'SAMEORIGIN' }));

const enumMap = require('../utils/enums');
const utils = require('../utils');

const airportsList = require('../data/airports_list.json');

const csrfProtection = require('../utils/csrf-middleware');

function logincheck(req, _res, next) {
    if (req.session && req.session.userEmail) {
        req.isLoggedInUser = true
    } else {
        req.isLoggedInUser = false
    }
    next();
}

/* flight search */
/* GET flights between two airports */
router.post('/search', validateSearchData, validateDateForTrip, (req, res) => {
    let { to, from, trip_type, pax } = req.body;
    /* find flights between from and two
    ignore rest of the params */

    let onward_flights, return_flights;
    try {
        if(trip_type === enumMap.trip_type_map.ONE_WAY) {
            onward_flights = computeFlightSearch(from, to, pax);
            return_flights = null;
        } else {
            onward_flights = computeFlightSearch(from, to, pax);
            return_flights = computeFlightSearch(to, from, pax);
        }
    } catch(err) {
        console.log(err);
        return res.status(err.statusCode || 500).send({
            status: err.status || false,
            message: err.message || "Something went wrong"
        })
    }

    return res.status(200).send({
        status: true,
        data: {
            onward_flights,
            return_flights
        }
    });
});

function computeFlightSearch(source, dest, pax) {
    const filtered_airports = airportsList.filter(elem => elem.icao);
    let from_airport = filtered_airports.find(elem => elem.code === source);
    if(!from_airport) {
        throw new Object({
            status: false,
            message: "Departing airport not found in the list",
            statusCode: 404
        });
    }
    let to_airport = filtered_airports.find(elem => elem.code === dest);
    if(!to_airport) {
        throw new Object({
            status: false,
            message: "Destination airport not found in the list",
            statusCode: 404
        });
    }
    from_airport = utils.addMetaToAirportInfo(from_airport);
    to_airport = utils.addMetaToAirportInfo(to_airport);

    const airport_airlines = require('../data/airport_airlines.json');

    // airlines operating from "from airport"
    const airlines_operating_from = from_airport['nick'] ? airport_airlines[from_airport['nick']] : [];
    if(!airlines_operating_from || !airlines_operating_from.length) {
        throw new Object({
            status: false,
            message: "No airlines found to be operating from departure airport",
            statusCode: 404
        });
    }

    // airlines operating from "from airport"
    const airlines_operating_to = to_airport['nick'] ? airport_airlines[to_airport['nick']] : [];
    if(!airlines_operating_to || !airlines_operating_to.length) {
        throw new Object({
            status: false,
            message: "No airlines found to be operating to destination airport",
            statusCode: 404
        });
    }

    // find intersecting airlines
    const intersecting_airlines = airlines_operating_from.filter(value => airlines_operating_to.includes(value));

    if(!intersecting_airlines.length) {
        throw new Object({
            status: false,
            message: "No flights connecting the cities",
            statusCode: 404
        });
    }

    //put some dummy price info, flight numbers, and time
    const airlines = require('../data/airlines.json');
    const airlines_arr = utils.arrayfy(airlines, 'airline');
    const results = [];

    for(let each_airline of intersecting_airlines) {
        const airline_obj = airlines_arr.find(elem => elem.name === each_airline);
        const payload = {
            airline: each_airline,
            flight_no: `${airline_obj ? airline_obj.IATA : utils.randomString(2)} ${utils.randomNumber(100, 9999)}`,
            fare: `$${utils.randomNumber(100, 999)}.${utils.randomNumber(1,99)}`,
            departureTime: `${String(utils.randomNumber(0,23)).padStart(2, '0')}:${String(utils.randomNumber(0,59)).padStart(2, '0')}`,
            flightDuration: `${utils.randomNumber(100,1500)} minutes`,
        };
        const fare = parseFloat(( pax.adult || 0 ) * Number(payload.fare.slice(1)) + ( pax.children || 0 ) * Number((payload.fare.slice(1)) * 0.75 )).toFixed(2);
        payload.totalFare = `$${fare}`;
        results.push(payload);
    }
    return results;
}

function validateSearchData(req, res, next) {
    let { to, from, trip_class, trip_type, pax } = req.body;
    // validation for payload
    if(!to || !from) {
        return res.status(400).send({
            status: false,
            message: "Source and Destination required"
        });
    }
    if(!trip_class) {
        req.body.trip_class = enumMap.trip_class_map.ECONOMY;
    } 
    if(!utils.validateEnumMap(enumMap.trip_class_map, req.body.trip_class)) {
        return res.status(400).send({
            status: false,
            message: "Invalid trip class"
        });
    }

    if(!trip_type) {
        req.body.trip_type = enumMap.trip_type_map.ONE_WAY;
    } 
    if(!utils.validateEnumMap(enumMap.trip_type_map, req.body.trip_type)) {
        return res.status(400).send({
            status: false,
            message: "Invalid trip type"
        });
    }

    if(!pax || (!pax.adult && !pax.children) ) {
        return res.status(400).send({
            status: false,
            message: "Passengers can not be zero"
        });
    }

    return next();
}

function validateDateForTrip(req, res, next) {
    let { date, trip_type } = req.body;
    if(!date || !date.departing) {
        return res.status(400).send({
            status: false,
            message: "Departing date must be set!"
        });
    } else if(date && !date.returning && trip_type === enumMap.trip_type_map.ROUND_TRIP) {
        return res.status(400).send({
            status: false,
            message: "Returning date must be set for round-trip flight!"
        });
    }

    if(date && !Date.parse(new Date(date.departing))) {
        return res.status(400).send({
            status: false,
            message: "Invalid departing date"
        });
    }

    if(date && date.returning && !Date.parse(new Date(date.returning))) {
        return res.status(400).send({
            status: false,
            message: "Invalid return date"
        });
    }
    return next();
}

/* GET flightbooking page. */
router.get('/', logincheck, csrfProtection, (req, res) => {
    res.render('flights', { isLoggedInUser: req.isLoggedInUser, userEmail: req.session.userEmail, _csrf: req.csrfToken() });
});


module.exports = router;
