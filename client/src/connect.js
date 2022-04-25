window.addEventListener('load', function () {
    if(ethereum.selectedAddress != null) {
        window.location.replace("index.html")
    }
})

const mmEnable = document.getElementById('mm-connect')

mmEnable.onclick = async () => {
    await ethereum.request({ method: 'eth_requestAccounts' })
    if(ethereum.selectedAddress != null) {
        window.location.replace("index.html")
    }
}