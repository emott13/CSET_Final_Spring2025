function colorBox(data) {
    checked = data.checked
    colorElem = data.parentElement.getElementsByClassName("custom-color")[0]
    existElem = data.parentElement.getElementsByClassName("exist-color")[0]

    existElem.style.display = checked ? "none" : ""
    colorElem.style.display = checked ? "" : "none"

    colorElem.children[0].children[0].disabled = !checked
    colorElem.children[1].children[0].disabled = !checked
    existElem.children[0].children[0].disabled = checked
}

function addURL(data) {
    len = data.parentElement.children.length
    console.log("Length of images div = " + len)
    html = `
        <div class="full-width">
            <div class="fancy-input">
                <input class="full-width" type="url" name="url-${len}" placeholder=""/>
                <label class="label-shown" for="url-${len}">Image URL:</label>
            </div>
        </div>`
    elem = document.createElement("div")
    elem.innerHTML = html
    data.parentElement.appendChild(elem)
}


if (window.history.replaceState)
    window.history.replaceState( null, null, window.location.href );

