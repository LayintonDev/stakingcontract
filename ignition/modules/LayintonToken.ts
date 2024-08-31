import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const LayintonTokenModule = buildModule("LayintonTokenModule", (m) => {

    const erc20 = m.contract("LayintonToken");

    return { erc20 };
});

export default LayintonTokenModule;
