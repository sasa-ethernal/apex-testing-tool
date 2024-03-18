import { check, sleep } from 'k6';
import exec from 'k6/x/exec';

const vus = 8;
const iterations = 3;

const wallets = 2; // Number of wallets generated at startup for each VUS (vus-#/wallet-# .addr|.skey|.vkey)
const initial_amount = 10000000; // Lovelace transfered to each VUS wallet (1Ada = 1000000Lovelace)
const sender_address = "test-data/local-keys/user"; // Path to address that will provide tokens (must contain *.addr and *.skey)

// Object where data can be stored between iterations
let vuData = {};

export const options = {
  // A number specifying the number of VUs to run concurrently.
  //vus: 300,
  // A string specifying the total duration of the test run.
  //duration: '50s',
  //iterations: 2,

  scenarios: {
    contacts: {
      executor: 'per-vu-iterations',
      vus: vus,
      iterations: iterations,
      maxDuration: '10m',
    },
  },
};

// Perform setup tasks in the setup() function
export function setup() {
  const scripts = exec.command("ls", [], {"dir": "scripts"}).split('\n').filter(file => file.endsWith('.sh'));
  scripts.forEach(file => {
    exec.command("chmod", ["+x", file], {
      "dir": "scripts"
    });
  })

  let commandOutput = exec.command("bash", ["scripts/startup.sh", vus, wallets, sender_address, initial_amount]);
  console.log(`Shell command output: ${commandOutput}`);

  console.log('Setup tasks executed');
}

// The function that defines VU logic.
//
// See https://grafana.com/docs/k6/latest/examples/get-started-with-k6/ to learn more
// about authoring k6 scripts.
//
export default function () {

  if (!vuData[__VU]) {
    vuData[__VU] = [];
  }

  // __VU starts from 1, __ITER starts from 0
  let vu_id = __VU - 1;

  let wallet0 = `test-data/vus-${vu_id}/wallet-0`;
  let wallet1 = `test-data/vus-${vu_id}/wallet-1`;

  // Generate new addresses
  // Startup already generated wallet-0|wallet-1 so we create wallet-100|wallet-101 to distinguish between them
  let address0 = exec.command("bash", ["scripts/generate_address.sh", vu_id, (__ITER * 100) + 50]).trim();
  let address1 = exec.command("bash", ["scripts/generate_address.sh", vu_id, (__ITER * 100) + 51]).trim();

  // Transfer 1 Ada from two wallets generated at startup to newly generated addresses
  let commandOutput = ""
  commandOutput = exec.command("bash", ["scripts/send_one_tx.sh", wallet0, address0, 2000000]);
  console.log(commandOutput)

  commandOutput = exec.command("bash", ["scripts/send_one_tx.sh", wallet1, address1, 2000000]);
  console.log(commandOutput)

  return
}

// Perform teardown tasks after the test completes
export function teardown() {

  exec.command("bash", ["scripts/teardown.sh", sender_address]);

  console.log('Teardown tasks executed');

}
