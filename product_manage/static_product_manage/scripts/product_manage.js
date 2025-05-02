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
    html = `
        <div class="full-width">
            <div class="fancy-input">
                <input class="full-width" type="url" name="url" placeholder=""/>
                <label class="label-shown" for="url">Image URL:</label>
            </div>
        </div>`
    elem = document.createElement("div")
    elem.innerHTML = html
    data.parentElement.appendChild(elem)
}

function addVariantURL(data) {
    editForm = document.getElementById("edit-form");
    html = `<input type="text" name="url" value="" form="edit-form"/>`;
    elem = document.createElement("td");
    elem.innerHTML = html;
    data.parentNode.parentNode.insertBefore(elem, data.parentNode);
}

if (window.history.replaceState)
    window.history.replaceState( null, null, window.location.href );

