let mainImageDOM = document.getElementsByClassName("product-img")[0]
let smallImagesDOM = document.getElementsByClassName("product-img-small")

document.addEventListener("click", (e) => {
    if(e.target.parentNode.className === "product-img-small") {
        mainImageDOM.src = e.target.src
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