import { useRef, useState } from "react";
import { NetworkOptions } from "./NetworkOptions";
import { getAddress } from "viem";
import { Address } from "viem";
import { useAccount, useDisconnect } from "wagmi";
import {
  ArrowLeftOnRectangleIcon,
  ArrowTopRightOnSquareIcon,
  ArrowsRightLeftIcon,
  CheckCircleIcon,
  ChevronDownIcon,
  DocumentDuplicateIcon,
  EyeIcon,
  QrCodeIcon,
} from "@heroicons/react/24/outline";
import { BlockieAvatar, isENS } from "~~/components/scaffold-eth";
import { useCopyToClipboard, useOutsideClick } from "~~/hooks/scaffold-eth";
import { getTargetNetworks } from "~~/utils/scaffold-eth";

const BURNER_WALLET_ID = "burnerWallet";

const allowedNetworks = getTargetNetworks();

type AddressInfoDropdownProps = {
  address: Address;
  blockExplorerAddressLink: string | undefined;
  displayName: string;
  ensAvatar?: string;
};

export const AddressInfoDropdown = ({
  address,
  ensAvatar,
  displayName,
  blockExplorerAddressLink,
}: AddressInfoDropdownProps) => {
  const { disconnect } = useDisconnect();
  const { connector } = useAccount();
  const checkSumAddress = getAddress(address);

  const { copyToClipboard: copyAddressToClipboard, isCopiedToClipboard: isAddressCopiedToClipboard } =
    useCopyToClipboard();
  const [selectingNetwork, setSelectingNetwork] = useState(false);
  const dropdownRef = useRef<HTMLDetailsElement>(null);

  const closeDropdown = () => {
    setSelectingNetwork(false);
    dropdownRef.current?.removeAttribute("open");
  };

  useOutsideClick(dropdownRef, closeDropdown);

  return (
    <>
      <details ref={dropdownRef} className="dropdown dropdown-end leading-3  ">
        <summary className="btn btn-secondary btn-sm pl-0 pr-2 shadow-md dropdown-toggle gap-0 h-auto! bg-white ">
          <BlockieAvatar address={checkSumAddress} size={30} ensImage={ensAvatar} />
          <span className="ml-2 mr-1">
            {isENS(displayName) ? displayName : checkSumAddress?.slice(0, 6) + "..." + checkSumAddress?.slice(-4)}
          </span>
          <ChevronDownIcon className="h-6 w-4 ml-2 sm:ml-0 bg-white " />
        </summary>
        <ul className="dropdown-content menu z-2 p-2 mt-2 shadow-lg bg-white border border-gray-200 rounded-box gap-1">
          <NetworkOptions hidden={!selectingNetwork} />
          <li className={selectingNetwork ? "hidden" : ""}>
            <div
              className="h-8 btn-sm flex gap-3 py-3 cursor-pointer bg-white hover:bg-gray-100 text-black rounded-lg"
              onClick={() => copyAddressToClipboard(checkSumAddress)}
            >
              {isAddressCopiedToClipboard ? (
                <>
                  <CheckCircleIcon className="text-xl font-normal h-6 w-4 ml-2 sm:ml-0 text-green-600" aria-hidden="true" />
                  <span className="whitespace-nowrap text-black">Copied!</span>
                </>
              ) : (
                <>
                  <DocumentDuplicateIcon className="text-xl font-normal h-6 w-4 ml-2 sm:ml-0 text-gray-600" aria-hidden="true" />
                  <span className="whitespace-nowrap text-black">Copy address</span>
                </>
              )}
            </div>
          </li>
          <li className={selectingNetwork ? "hidden" : ""}>
            <label htmlFor="qrcode-modal" className="h-8 btn-sm flex gap-3 py-3 bg-white hover:bg-gray-100 text-black rounded-lg cursor-pointer">
              <QrCodeIcon className="h-6 w-4 ml-2 sm:ml-0 text-gray-600" />
              <span className="whitespace-nowrap text-black">View QR Code</span>
            </label>
          </li>
          <li className={selectingNetwork ? "hidden" : ""}>
            <button className="h-8 btn-sm flex gap-3 py-3 bg-white hover:bg-gray-100 text-black rounded-lg" type="button">
              <ArrowTopRightOnSquareIcon className="h-6 w-4 ml-2 sm:ml-0 text-gray-600" />
              <a
                target="_blank"
                href={blockExplorerAddressLink}
                rel="noopener noreferrer"
                className="whitespace-nowrap text-black"
              >
                View on Block Explorer
              </a>
            </button>
          </li>
          {allowedNetworks.length > 1 ? (
            <li className={selectingNetwork ? "hidden" : ""}>
              <button
                className="h-8 btn-sm flex gap-3 py-3 bg-white hover:bg-gray-100 text-black rounded-lg"
                type="button"
                onClick={() => {
                  setSelectingNetwork(true);
                }}
              >
                <ArrowsRightLeftIcon className="h-6 w-4 ml-2 sm:ml-0 text-gray-600" /> <span className="text-black">Switch Network</span>
              </button>
            </li>
          ) : null}
          {connector?.id === BURNER_WALLET_ID ? (
            <li>
              <label htmlFor="reveal-burner-pk-modal" className="h-8 btn-sm flex gap-3 py-3 bg-white hover:bg-gray-100 text-red-600 rounded-lg cursor-pointer">
                <EyeIcon className="h-6 w-4 ml-2 sm:ml-0 text-red-600" />
                <span className="text-red-600">Reveal Private Key</span>
              </label>
            </li>
          ) : null}
          <li className={selectingNetwork ? "hidden" : ""}>
            <button
              className="menu-item h-8 btn-sm flex gap-3 py-3 bg-white hover:bg-gray-100 text-red-600 rounded-lg"
              type="button"
              onClick={() => disconnect()}
            >
              <ArrowLeftOnRectangleIcon className="h-6 w-4 ml-2 sm:ml-0 text-red-600" /> <span className="text-red-600">Disconnect</span>
            </button>
          </li>
        </ul>
      </details>
    </>
  );
};
