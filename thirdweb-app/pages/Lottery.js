import {
  useAddress,
  useContract,
  Web3Button,
  useContractRead,
  ConnectWallet,
} from "@thirdweb-dev/react";
import styles from "../styles/Home.module.css";

export default function Lottery() {
  const LOTTERY_CONTRACT = "0x887b43De13084711c35293F7bA5501d410172770";
  const { contract } = useContract(LOTTERY_CONTRACT);

  const { data: balance } = useContractRead(contract, "getBalance");
  const formatBalance = balance ? ethers.utils.formatEther(balance) : 0;

  const { data: players } = useContractRead(contract, "getPlayers");
  const { data: lastWinner } = useContractRead(contract, "lastWinner");

  const address = useAddress();
  const { data: manager } = useContractRead(contract, "manager");
  const isManager = manager === address;

  return (
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
            <h3>合約發起者具有看講資格</h3>
            {isManager && (
              <Web3Button
                contractAddress={LOTTERY_CONTRACT}
                action={async () => {
                  await contract.call("pickWinner", [], {});
                }}
                onSuccess={() => alert("開獎成功")}
                onError={() => alert("開獎失敗")}
              >
                開獎
              </Web3Button>
            )}
            <div></div>
            <Web3Button
              contractAddress={LOTTERY_CONTRACT}
              action={async () => {
                await contract.call("enter", [], {
                  value: ethers.utils.parseEther("0.01"),
                });
              }}
              onSuccess={() => alert("參加成功")}
              onError={() => alert("參加失敗")}
            >
              參加樂透 0.01 ET
            </Web3Button>
            {/* <div>{address}</div> */}
          </div>

          <div class="card">
            <h3>累積獎金 ETH</h3>
            <p>{formatBalance}</p>
          </div>

          <div class="card">
            <h3>本期投入人數</h3>
            <p>{players?.length}</p>
          </div>

          <div class="card">
            <h3>上次大獎得主</h3>
            <p>{lastWinner}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
