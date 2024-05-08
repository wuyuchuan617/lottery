import { useState } from "react";
import {
  ConnectWallet,
  useContract,
  Web3Button,
  useAddress,
  useContractRead,
  useContractWrite,
} from "@thirdweb-dev/react";
import styles from "../styles/Home.module.css";
import { ethers } from "ethers";

export default function Carbon() {
  const [registAmount, setRegistAmount] = useState(1);
  const [emmisionAmount, setEmmisionAmount] = useState(0);
  const [buyAmount, setBuyAmount] = useState(1000);
  const [offsetAmount, setOffsetAmount] = useState(1);

  const CARBON_CONTRACT = "0x4C78C2F1b6a9B745FF99da594ABbEd33f9833F4B";
  const { contract } = useContract(CARBON_CONTRACT);

  const address = useAddress();
  const {
    mutateAsync: register,
    isLoading,
    error,
  } = useContractWrite(contract, "register");
  const { mutateAsync: claimEmmision } = useContractWrite(
    contract,
    "claimEmmision"
  );
  const { mutateAsync: buy } = useContractWrite(contract, "buy");
  const { mutateAsync: offset } = useContractWrite(contract, "offset");

  const { data: emission } = useContractRead(contract, "emission", [address]);
  const { data: balance } = useContractRead(contract, "balanceOf", [address]);
  const { data: feeData } = useContractRead(contract, "calulateFee", [
    buyAmount,
  ]);

  const formatBalance = balance ? ethers.utils.formatEther(balance) : 0;

  return (
    <main className={styles.main}>
      <div className={styles.container}>
        <div className={styles.header}>
          <h1 className={styles.title}>
            Welcome to{" "}
            <span className={styles.gradientText0}>
              <a
                href="https://thirdweb.com/"
                target="_blank"
                rel="noopener noreferrer"
              >
                Lottery
              </a>
            </span>
          </h1>
          <div class="w-8/12 m-auto">
            <div class="flex justify-center mt-6">
              <ConnectWallet />
            </div>

            <div class="card">
              <h3>Register Amount</h3>
              <input
                value={registAmount}
                onChange={(e) => setRegistAmount(e.target.value)}
              ></input>
              <Web3Button
                contractAddress={CARBON_CONTRACT}
                action={async () => {
                  await register({ args: [registAmount] });
                  setRegistAmount(1);
                }}
              >
                Register
              </Web3Button>
            </div>

            <div class="card">
              <h3>Claim Emmision Amount</h3>
              <input
                value={emmisionAmount}
                onChange={(e) => setEmmisionAmount(e.target.value)}
              ></input>
              <Web3Button
                contractAddress={CARBON_CONTRACT}
                action={async () => {
                  await claimEmmision({ args: [emmisionAmount] });
                  setEmmisionAmount(0);
                }}
              >
                Claim Emmision
              </Web3Button>
            </div>

            <div class="card">
              <h3>Buy Amount</h3>
              <input
                value={buyAmount}
                onChange={(e) => setBuyAmount(e.target.value)}
              ></input>
              <p>Fee:</p>
              <p>Protocal Fee:</p>
              <Web3Button
                contractAddress={CARBON_CONTRACT}
                action={async () => {
                  await buy({ args: [emmisionAmount] });
                  setBuyAmount(0);
                }}
              >
                Buy
              </Web3Button>
            </div>

            <div class="card">
              <h3>Offset Amount</h3>
              <input
                value={offsetAmount}
                onChange={(e) => setOffsetAmount(e.target.value)}
              ></input>
              <Web3Button
                contractAddress={CARBON_CONTRACT}
                action={async () => {
                  await offset({ args: [offsetAmount] });
                  setOffsetAmount(0);
                }}
              >
                Offset
              </Web3Button>
            </div>

            <div class="card">
              <h3>Token 餘額</h3>
              <p>{formatBalance}</p>
            </div>

            <div class="card">
              <h3>Total Emission</h3>
              <p>{emission?.toString()}</p>
            </div>

            {/*  <div class="card">
              <h3>上次大獎得主</h3>
              <p>{lastWinner}</p>
            </div> */}
          </div>
        </div>
      </div>
    </main>
  );
}
