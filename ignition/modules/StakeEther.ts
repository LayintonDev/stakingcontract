import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const StakeEtherModule = buildModule("StakeEtherModule", (m) => {

    const save = m.contract("StakeEther");

    return { save };
});

export default StakeEtherModule;