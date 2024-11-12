const airportsListAdditionalMeta = require('../data/airports_list_additional_metadata.json');

const isEmptyList = (list) => {
    return list instanceof Array && list && list.length ? false : true;
}

const arrayfy = (obj, key) => {
    const transformed = [];
    for(let meta in obj) {
        transformed.push({
            [key]: meta,
            ...obj[meta]
        })
    }
    return transformed;
}

const paginate = (array, page_size, page_number) => {
    // human-readable page numbers usually start with 1, so we reduce 1 in the first argument
    return array.slice((page_number - 1) * page_size, page_number * page_size);
}

const prepareResults = (results, cb) => {
    return results.map(elem => cb(elem)).sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()));
}

const validateEnumMap = (map, str) => {
    return Object.values(map).includes(str.trim());
}

const randomNumber = (min, max) => { 
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

const randomString = (length) => {
    let result           = '';
    const characters       = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const charactersLength = characters.length;
    for ( let i = 0; i < length; i++ ) {
        result += characters.charAt(Math.floor(Math.random() * charactersLength));
    }
    return result;
}

const addMetaToAirportInfo = (airport) => {
    const arrayfied_airportsListAdditionalMeta = arrayfy(airportsListAdditionalMeta, 'airport');
    const transformedMeta = arrayfied_airportsListAdditionalMeta;
    const metaElem = transformedMeta.find(metaItem => airport.code === metaItem.iata );
    if(metaElem) {
        airport['nick'] = metaElem.airport;
        airport['airlinesFlying'] = metaElem.airlinesFlying;
    }
    return airport;
}

module.exports = {
    isEmptyList,
    arrayfy,
    prepareResults,
    validateEnumMap,
    randomNumber,
    randomString,
    addMetaToAirportInfo,
    paginate
}