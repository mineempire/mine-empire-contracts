
import Web3 from 'web3';
window.addEventListener('load', function () {
    // Check for MetaMask
    if (typeof window.ethereum !== 'undefined' && window.ethereum.isMetaMask === true) {
        console.log('window.ethereum is enabled')
        console.log('MetaMask is active')

        if(ethereum.selectedAddress == null) {
            window.location.replace("connect.html")
        }
    } else {
        mmDetected.innerHTML = 'MetaMask is not available'
        this.alert('Please install MetaMask to use this dapp')
    }

});
