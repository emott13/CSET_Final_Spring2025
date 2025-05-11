let mainImageDOM = document.getElementsByClassName("product-img")[0]
let smallImagesDOM = document.getElementsByClassName("product-img-small")
let productSortDOM = document.getElementById("product-sort")
let productFilterDOM = document.getElementById("product-filter")
let reviewsDOM = document.getElementsByClassName("product-review");


function compareDate(a, b) {
    if (a.dataset.date < b.dataset.date)
        return 1;
    if (a.dataset.date > b.dataset.date)
        return -1;
    return 0;
}

function compareRating(a, b) {
    if (a.dataset.rating < b.dataset.rating)
        return 1;
    if (a.dataset.rating > b.dataset.rating)
        return -1;
    return 0;
}



document.addEventListener("click", (e) => {
    if(e.target.parentNode.className == "product-img-small") {
        mainImageDOM.src = e.target.src
    }
    
});

productSortDOM.addEventListener("change", (e) => {
    sort = productSortDOM.value

    let elems = document.querySelectorAll(".product-review");
    let elemsArray = Array.from(elems);
    let sorted

    if (sort === "pos")
        sorted = elemsArray.sort(compareRating);
    else if (sort === "crit") {
        sorted = elemsArray.sort(compareRating);
        sorted.reverse()
    }
    else
        sorted = elemsArray.sort(compareDate);

    sorted.forEach(e =>
        document.querySelectorAll(".product-reviews-container")[0].appendChild(e)
    );
});

productFilterDOM.addEventListener("change", (e) => {
    filter = productFilterDOM.value
    console.log("Filter = " + filter);

    for (let review of reviewsDOM) {
        display = "none"
        rating = review.dataset.rating
        if (filter === "all")
            display = "block";
        else if (filter === "pos") {
            if (Number(rating) >= 4)
                display = "block";
        }
        else if (filter === "crit") {
            console.log("crit")
            if (Number(rating) <= 2)
                display = "block";
        }
        else if (rating === filter)
            display = "block";
            
        
        review.style.display = display
    }
});

if (window.history.replaceState)
    window.history.replaceState( null, null, window.location.href );

function checkNum(data) {
    if (isNaN(data.value))
        data.value = 1;
    else if (Number(data.value) < Number(data.min))
        data.value = 1;
    else if (Number(data.value) > Number(data.max))
        data.value = data.max;

}

// let originalSize = document.getElementById("size-selected").text;
// let sizeContainers = document.getElementsByClassName("variant-size-container");

// for (sizeContainer of sizeContainers) {
//     sizeContainer.addEventListener("mouseenter", (e) => {
//         console.log(sizeContainer);
//         document.getElementById("size-selected").text = sizeContainer.getElementsByClassName("variant-size")[0].textContent;
//     })

//     sizeContainer.addEventListener("mouseleave", (e) => {
//         document.getElementById("size-selected").text = originalSize;
//     })
// }