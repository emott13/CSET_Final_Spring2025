let mainImageDOM = document.getElementsByClassName("product-img")[0]
let smallImagesDOM = document.getElementsByClassName("product-img-small")

document.addEventListener("click", (e) => {
    if(e.target.parentNode.className === "product-img-small") {
        mainImageDOM.src = e.target.src
    }
    
});

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