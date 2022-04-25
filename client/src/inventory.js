const minersDiv = document.getElementById('js-produced-miners')
window.addEventListener('load', function () {
    for (let i = 0; i < 3; i++) {
        minersDiv.innerHTML += `
        <div id="equipment-item${i}" onmouseover="changeBackgroundActiveItem(this)" onmouseout="changeBackgroundInactiveItem(this)" onclick="expandItem(this, ${i})">
            <div id="equipment-item-title${i}">
                <p>Basic Miner</p>
            </div>
            <div id="description-item-title${i}">
                <p>Mine Coal, Iron, Silver</p>
            </div>
            <div id="stat1-item-title${i}">
                <p>Lv 1</p>
            </div>
            <div id="stat2-item-title${i}">
                <p>Lv 1</p>
            </div>
        </div>
        `
        setOuterDivStyles('equipment-item'+i)
        setInnerDivStyles('equipment-item-title'+i)
        setInnerDivStyles('description-item-title'+i)
        setInnerDivStyles('stat1-item-title'+i)
        setInnerDivStyles('stat2-item-title'+i)

        minersDiv.innerHTML += `
        <div id=equipment-drop${i}>
            <div id="equipment-item-drop${i}">
            </div>
            <div id="description-item-drop${i}">
                <p>The basic miner can be staked inside of Coal, Iron and Silver mines. Upgrade your miner to increase production.</p>
            </div>
            <div id="stat1-item-drop${i}">
                <p>Production Multiplier: 1x</p>
                <p>Next Upgrade: 1x -> 1.25x</p>
                <br>
                <p>Balance / Upgrade Cost</p>
                <p>Coal: 800 / 1000 </p>
                <button id="upgrade-mining-power">upgrade</button>
            </div>
            <div id="stat2-item-drop${i}">
                <p>Production Capacity: 50</p>
                <p>Next Upgrade: 50 -> 75</p>
                <br>
                <p>Balance / Upgrade Cost</p>
                <p>Coal: 800 / 750 </p>
                <button id="upgrade-capacity-power">upgrade</button>
            </div>
        </div>
        `

        setInnerDivStylesDrop('equipment-item-drop'+i)
        setInnerDivStylesDrop('description-item-drop'+i)
        setInnerDivStylesDrop('stat1-item-drop'+i)
        setInnerDivStylesDrop('stat2-item-drop'+i)
        setOuterDivStylesDrop('equipment-drop'+i)
        const hideDiv = document.getElementById('equipment-drop'+i)
        hideDiv.style.display = 'none'
    }

    console.log(minersDiv.children.length)
})
function setOuterDivStyles(id) {
    let item = document.getElementById(id)
    item.style.display = 'flex'
    item.style.alignItems = 'center'
    item.style.justifyContent = 'center'
    item.style.background = '#ce8888'
    item.style.margin = 'auto'
    item.style.width = '800px'
}
function setInnerDivStyles(id) {
    let item = this.document.getElementById(id)
    item.style.flexBasis = '200px'
    item.style.height = '50px'
    item.style.textAlign = 'center'
}
function setOuterDivStylesDrop(id) {
    let item = document.getElementById(id)
    item.style.display = 'flex'
    item.style.alignItems = 'center'
    item.style.justifyContent = 'center'
    item.style.background = '#c4aead'
    item.style.margin = 'auto'
    item.style.width = '800px'
}
function setInnerDivStylesDrop(id) {
    let item = this.document.getElementById(id)
    item.style.flexBasis = '200px'
    item.style.height = '300px'
    item.style.textAlign = 'center'
}

function changeBackgroundActiveItem(item) {
    item.style.backgroundColor = '#55d6aa'
}

function changeBackgroundInactiveItem(item) {
    item.style.backgroundColor = '#ce8888'
}

function expandItem(item, itemNumber) {
    const unhideDiv = document.getElementById('equipment-drop'+itemNumber)
    if (unhideDiv.style.display == 'none') {
        unhideDiv.style.display = 'flex'
    } else {
        unhideDiv.style.display = 'none'
    }
}
