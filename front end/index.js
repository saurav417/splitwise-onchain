import Web3 from "web3";
async function connectToMetaMask() {
  try {
    if (window.ethereum) {
      await window.ethereum.request({ method: "eth_requestAccounts" });

      const addresses = await window.ethereum.request({
        method: "eth_accounts",
      });
      const address = addresses[0];

      console.log(`Connected to MetaMask with address: ${address}`);
    } else {
      console.error(
        "MetaMask not detected. Please install MetaMask extension."
      );
    }
  } catch (error) {
    console.error("Error connecting to MetaMask:", error.message);
  }
}

document.addEventListener("DOMContentLoaded", () => {
  const connectButton = document.getElementById("connect-button");

  if (connectButton) {
    connectButton.addEventListener("click", connectToMetaMask);
  } else {
    console.error("Connect button not found in the DOM.");
  }
});
