function showResults(val, type_of_airport) {
    const res = document.getElementById(config[type_of_airport]['selector_id']);
    res.innerHTML = '';
    const not_found = document.getElementById(config[type_of_airport]['error_label_id']);

    if (val == '') {
        res.style.display = "none";
        not_found.style.display = "none";
        return;
    }

    let list = document.createElement("option");
    list.selected = true;
    list.disabled = true;
    list.innerHTML = "Loading...";
    res.appendChild(list);

    fetch('/airports?q=' + val).then(
        function (response) {
            return response.json();
        }).then(function (data) {
            list = null;
            while (res.firstChild) {
                res.removeChild(res.lastChild);
            }
            if (data.status && data.data.length) {
                let results_arr = [];
                for(let each of data.data) {
                    results_arr.push({
                        city : each.city,
                        name: each.name,
                        code : each.code
                    });
                }
                res.style.display = "block";
                not_found.style.display = "none";
                let list_first_elem = document.createElement("option");
                list_first_elem.disabled = true;
                list_first_elem.selected = true;
                list_first_elem.innerHTML = "Please select a city / airport";
                res.appendChild(list_first_elem);
                for(let each of results_arr) {
                    list = document.createElement("option");
                    list.value = each.code;
                    list.innerHTML = `${each.city} - ${each.name}`;
                    res.appendChild(list);
                }
                return true;
            } else {
                res.style.display = "none";
                not_found.style.display = "block";
                return false;
            }    
        }).catch(function (err) {
            list = document.createElement("option");
            list.value = '';
            list.selected = true;
            list.innerHTML = "Error fetching list of cities / airports";
            res.appendChild(list);
            console.warn('Something went wrong.', err);
            return false;
        });
}

function setSelection(selected_val, type_of_airport ) {
    document.getElementById(config[type_of_airport]['input_field_id']).value = selected_val;
    document.getElementById(config[type_of_airport]['selector_id']).style.display = "none";
}

function debounce(func, timeout = 300){
    let timer;
    return (...args) => {
      clearTimeout(timer);
      timer = setTimeout(() => { func.apply(this, args); }, timeout);
    };
}

const airport_results = debounce(showResults);

function hideItems(items) {
    for(let each of items) {
        each.style.display = "none";
    }
}

document.addEventListener('DOMContentLoaded', function() {
    const select_dropdowns = document.getElementsByClassName('city_results');

    document.addEventListener('click', function(event) {
        event.stopPropagation();
        for(let each_select_dropdown of select_dropdowns) {
            const isClickInsideElement = each_select_dropdown.contains(event.target);
            if (!isClickInsideElement) {
                each_select_dropdown.style.display = "none";
            }
        }
    });

    for(let each_select_dropdown of select_dropdowns) {
        each_select_dropdown.addEventListener('change', function(event) {
            const selected_val = event.target.value;
            const id_of_select_dropdown = each_select_dropdown.id;
            const type_of_airport = id_of_select_dropdown.split('_')[1];
            return setSelection(selected_val, type_of_airport); 
        });
    }

    const city_results_input_fields = document.getElementsByClassName('city_results_input');

    for(let city_result_input_field of city_results_input_fields ) {
        city_result_input_field.addEventListener("keyup", function(event) {
            event.stopPropagation();
            const id = event.target.id;
            const type_of_airport = id.split('_')[1];
            const value = event.target.value;
            return airport_results(value, type_of_airport);
        });
    }

    const city_results_selectors = document.getElementsByClassName('city_results');
    hideItems(city_results_selectors);

    const err_airport_not_found_labels = document.getElementsByClassName('err-airport-not-found');
    hideItems(err_airport_not_found_labels);
});