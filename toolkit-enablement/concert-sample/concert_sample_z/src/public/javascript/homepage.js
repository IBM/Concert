document.addEventListener('DOMContentLoaded', function() {
    // login modal functions
    document.addEventListener('modal-shown', (evt) => {
        const first = evt.target.querySelectorAll('input')[0];
        first.focus();
    });

    document.addEventListener('modal-hidden', (evt) => {
        const first = evt.target.querySelectorAll('input')[0];
        first.blur();
    });

    const flight_button = document.getElementById("flight-button");
    flight_button.addEventListener('click', (event) => {
        event.stopPropagation();
        window.location.href = "/flightbooking"
    })
})