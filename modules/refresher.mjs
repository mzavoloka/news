// Reload page to avoid memory leaks
function setRefresher() {
    setTimeout(function(){
        location.reload();
    }, 30 * 60 * 1000); // every 30 minutes
}

export { setRefresher };
