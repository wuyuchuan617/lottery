//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    error Unauthorized();
    error InvalidOwner();

    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    constructor(address _owner) {
        if (_owner == address(0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    function transferOwnership(address _owner) public virtual onlyOwner {
        if (_owner == address(0)) revert InvalidOwner();

        owner = _owner;

        emit OwnershipTransferred(msg.sender, _owner);
    }

    function revokeOwnership() public virtual onlyOwner {
        owner = address(0);

        emit OwnershipTransferred(msg.sender, address(0));
    }
}

abstract contract ERC721Receiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721Receiver.onERC721Received.selector;
    }
}

/// @notice ERC404
///         A gas-efficient, mixed ERC20 / ERC721 implementation
///         with native liquidity and fractionalization.
///
///         This is an experimental standard designed to integrate
///         with pre-existing ERC20 / ERC721 support as smoothly as
///         possible.
///
/// @dev    In order to support full functionality of ERC20 and ERC721
///         supply assumptions are made that slightly constraint usage.
///         Ensure decimals are sufficiently large (standard 18 recommended)
///         as ids are effectively encoded in the lowest range of amounts.
///
///         NFTs are spent on ERC20 functions in a FILO queue, this is by
///         design.
///
abstract contract ERC404 is Ownable {
    // Events
    // ERC20 Events
    event ERC20Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // ERC721 Events
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event ERC721Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    // Errors
    error NotFound();
    error AlreadyExists();
    error InvalidRecipient();
    error InvalidSender();
    error UnsafeRecipient();

    // Metadata
    /// @dev Token name
    // 此資產的 name，既是 ERC20 代幣 name，也是 ERC721 name。
    string public name;

    /// @dev Token symbol
    // 此資產的symbol，既是ERC20代幣symbol，也是ERC721的symbol。
    string public symbol;

    /// @dev Decimals for fractional representation
    // 專給ERC20 用的狀態變量，預設為18，與 ERC20 合約預設一樣。
    uint8 public immutable decimals;

    /// @dev Total supply in fractionalized representation
    // 專給ERC20 用的狀態變量，預設為18，與 ERC20 合約預設一樣。
    uint256 public immutable totalSupply;

    /// @dev Current mint counter, monotonically increasing to ensure accurate ownership
    // 專給 ERC721 用的狀態變量，表示目前 NFT Mint 到幾號。
    uint256 public minted;

    // Mappings
    /// @dev Balance of user in fractional representation
    // 專給 ERC20 用的狀態變量，是一個 mapping 結構，記錄某地址持有的 ERC20 幣量。如果持有一顆 NFT 則會顯示 1 * 10 **18
    mapping(address => uint256) public balanceOf;

    /// @dev Allowance of user in fractional representation
    // 專給 ERC20 用的狀態變量，是一個巢狀的 mapping 結構，記錄某地址授權給某地址多少 ERC20 代幣，Ex: A 地址授權給 B 地址動用他 1 顆ERC20代幣(allowance[A][B] = 1 * 10 **18)
    mapping(address => mapping(address => uint256)) public allowance;

    /// @dev Approval in native representaion
    // 專給 ERC721 用的狀態變量，是一個 mapping 結構，記錄某地址授權哪個 tokenId 的 NFT 給哪個地址。
    mapping(uint256 => address) public getApproved;

    /// @dev Approval for all in native representation
    // 專給 ERC721 用的狀態變量，是一個巢狀的 mapping 結構，記錄某地址是否授權給某地址所有 NFT 操作的權限。Ex: A地址授權所有NFT給B地址，isApprovedForAll[A][B] = true。
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /// @dev Owner of id in native representation
    // 專給 ERC721 用的狀態變量，是一個 mapping 結構，記錄某 NFT tokenId 的擁有者是那個地址
    mapping(uint256 => address) public _ownerOf;

    /// @dev Array of owned ids in native representation
    // 專給 ERC721 用的狀態變量，是一個 mapping 結構，記錄某地址持有的所有 tokenId 陣列。
    mapping(address => uint256[]) public _owned;

    /// @dev Tracks indices for the _owned mapping
    // 用來輔助 owned mapping 的 mapping 結構，記錄某 tokenId 在_owned 中某地址持有的列表中的 index 資訊。Ex: 地址A擁有tokenIds有0,2,4，_owned[A] = [0, 2, 4]，而ownedIndex的記錄會長得像這樣：ownedIndex[0] = 0, ownedIndex[2] = 1, ownedIndex[4] = 2。
    // TODO: 這是什麼情情況拿來用的？
    mapping(uint256 => uint256) internal _ownedIndex;

    /// @dev Addresses whitelisted from minting / burning for gas savings (pairs, routers, etc)
    // 是一個 mapping 結構，基本上 ERC404 在轉移時，可能伴隨著 burn和 mint 的行為，輸入為白名單的地址，如果他是發送方，將不會 burn NFT，如果他是接收方，將不會 mint NFT。
    mapping(address => bool) public whitelist;

    // Constructor
    // 1. 直接指定給 name 狀態變量，作為此 ERC404 資產的 name（ERC20及ERC721的name）
    // 2. 直接指定給 symbol 狀態變量，作為此 ERC404 資產的 symbol（ERC20 及 ERC721 的 symbol）
    // 3. 直接指定給 decimals 狀態變量，作為之後 ERC20的最小單位。
    // 4. 直接指定給 totalSupply 狀態變量，表示 ERC20 發行總數。
    // 5. Ownable 初始化，直接指定給繼承的 Ownable.sol 合約的 owner 狀態變量，代表此ERC404合約的擁有者。
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalNativeSupply, address _owner)
        Ownable(_owner)
    {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalNativeSupply * (10 ** decimals);
    }

    // 這個 function 是用來設定白名單用的，被設為白名單的地址，只涉及 ERC20 的操作，不涉及 NFT 的操作(burn & mint)。
    /// @notice Initialization function to set pairs / etc
    ///         saving gas by avoiding mint / burn on unnecessary targets
    function setWhitelist(address target, bool state) public onlyOwner {
        // target: 欲設定為白名單的地址。
        // state: 若為 true，代表 target 地址將設中為白名單，反之，則非白名單。
        // 將 whitelist 這個 mapping 結構的狀態變量添增一筆紀錄，讓 target 地址，對應到 state。
        // 若 state 為 true 則表示t arget 為白名單，反之，則不為白名單
        whitelist[target] = state;
    }

    // 這個 function 與 ERC721 的 ownerOf 基本上功能一樣，就是查詢某 NFT tokenId 是那個地址所持有。
    /// @notice Function to find owner of a given native token
    function ownerOf(uint256 id) public view virtual returns (address owner) {
        // id: NFT 的 tokenId。

        // 直接呼叫狀態變量 _ownerOf 這個mapping結構，取得相應結果
        owner = _ownerOf[id];

        // 判斷owner是否為零地址 ，如果為零地址，則拋出NoFound Error。
        if (owner == address(0)) {
            revert NotFound();
        }
    }

    // 這個 function 與 ERC721 的 tokebURI 基本上功能一樣，但這邊將其抽象化，因此，繼承 ERC404 合約的子類別需要實作此 function，此 function 的用途為輸出 NFT 的 token metadata 記錄位址(ex: IPFS 位址)。
    // id: NFT 的 tokenId。
    /// @notice tokenURI must be implemented by child contract
    function tokenURI(uint256 id) public view virtual returns (string memory);

    // approve function 主要就是用來授權 NFT 或 ERC20 代幣給第三方使用的功能。這邊的 approve 結合了 ERC721 及 ERC20 的 approve，也就是同一個approve function，可以用來 approve ERC20，也可以用來 approve NFT。
    /// @notice Function for token approvals
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function approve(address spender, uint256 amountOrId) public virtual returns (bool) {
        // 1. spender：要授權的第三方地址
        // 2. amountOrId：ERC20 的 amount 或 ERC721 的 tokenId，下面會詳細說明他如何區分帶入的數值是 amount 還是 tokenId 。

        // 1: 判斷輸入的參數 amountOrId 的值是否小於目前 NFT 的發行數量且大於 0，如果是，則amountOrId 被當作 tokenId ，否則 amountOrId 被當作 amount。 這樣的判斷方式可以初步推估原因如下，因為通常 ERC20 的amount 是以最小單位計量，預設是 10 **18，所以 amount 通常不會太小，大多都是天文數字，但如果真的想要授權超小量的 amount，可能會被誤判為tokenId。

        // 2-1: 若判斷為 tokenId
        if (amountOrId <= minted && amountOrId > 0) {
            // 2-1-1: 取出該 tokenId 的 owner 地址。
            address owner = _ownerOf[amountOrId];

            // 2-1-2: 判斷若發起交易的人不為 tokenId 的 owner，或沒有被授權可以操作該NFT，則拋出錯誤。
            if (msg.sender != owner && !isApprovedForAll[owner][msg.sender]) {
                revert Unauthorized();
            }

            // 2-1-3: 添增 getApproval 記錄，以授權 spender 可動用該 tokenId 的NFT。
            getApproved[amountOrId] = spender;

            // 2-1-4: 拋出 Approval 事件，以利前端得知完成 Approve 行為。
            emit Approval(owner, spender, amountOrId);
        } else {
            // 2-2: 若判斷為 amount：
            // 2-2-1: 直接添增 allowance 記錄，以授權 spender 可動用 amount 個ERC20 代幣。
            allowance[msg.sender][spender] = amountOrId;

            // 2-2-2: 拋出 Approval 事件，以利前端得知完成 Approve 行為。
            emit Approval(msg.sender, spender, amountOrId);
        }

        return true;
    }

    // setApprovalForAll function，就是新增/修改狀態變量 isApprovedForAll，以記錄呼叫者是否授權所有 NFT 操作權給 operator。
    /// @notice Function native approvals
    function setApprovalForAll(address operator, bool approved) public virtual {
        // 1. operator : 呼叫者要授權所有 NFT 操作權的對象。
        // 2. approved : 是否要授權，true 表示授權，false 則表是不授權。

        // 1: 直接設定狀態變量 isApprovedForAll，若 approved 為 true ，則授權 operator 動用呼叫者的所有 NFT。
        isApprovedForAll[msg.sender][operator] = approved;

        // 2: 拋出 ApprovalForAll 事件，以利前端得知完成 ApprovalForAll 行為。
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // transferFrom function 不管是 ERC20 或 ERC721 都有此 function，在 ERC404 中，亦將它整合在一起，主要用途即為轉移 NFT 或 ERC20 代幣。
    /// @notice Function for mixed transfers
    /// @dev This function assumes id / native if amount less than or equal to current max id
    function transferFrom(address from, address to, uint256 amountOrId) public virtual {
        // 1. from : 資產 (ERC20/ NFT) 的持有者。
        // 2. to : 資產 (ERC20/ NFT) 的接收者。
        // 3. amountOrId : 資產 (ERC20/ NFT) 的 amount 或 tokenId。

        // 1: 判斷輸入的參數 amountOrId 的值是否小於目前 NFT 的發行數量且大於 0，如果是，則amountOrId 被當作 tokenId ，否則 amountOrId 被當作 amount。為什麼這邊不需要 && amountOrId > 0 ?
        // Step2–1: 若判斷為tokenId：
        if (amountOrId <= minted) {
            // Step2–1–1: 判斷如果 NFT tokenId 的擁有者不是 from 參數帶入的地址，怎拋出InvalidSender Error。
            if (from != _ownerOf[amountOrId]) {
                revert InvalidSender();
            }

            // Step2–1–2: 判斷如果 to 參數為零地址，怎拋出 InvalidRecipient Error
            // if (to == address(0)) {
            //     revert InvalidRecipient();
            // }

            // Step2–1–3: 判斷如果 from 參數不是呼叫者，且呼叫者必沒有被授權操作此NFT，則拋出 Unauthorized Error。
            if (msg.sender != from && !isApprovedForAll[from][msg.sender] && msg.sender != getApproved[amountOrId]) {
                revert Unauthorized();
            }

            // Step2–1–4: 將 from 的 balance 從 balanceOf 的 mapping 中減少一顆ERC20 代幣，因為一個 NFT 對應一顆 ERC20。
            // _getUnit() 回傳一顆 ERC20 以最小單位計數的 amount。 Ex: 一顆 ERC20 = 10 ** 18，那就會回傳 10 **18。
            balanceOf[from] -= _getUnit();

            // Step2–1–5: 將 to 的 balance 從 balanceOf 的 mapping 中增加一顆 ERC20代幣。
            // unchecked 作用？ 不檢查是否溢出
            unchecked {
                balanceOf[to] += _getUnit();
            }

            // Step2–1–6: 更改 ownerOf mapping 中 tokenId 對應的 owner，將其改為 to地址。
            _ownerOf[amountOrId] = to;

            // Step2–1–7: 清掉 getApproval mapping 中關於此 NFT tokenId 的記錄，以免讓曾授權過的地址能操作此 NFT。
            delete getApproved[amountOrId];

            // update _owned for sender
            // Step2–1–8: 接下來這步驟主要要來更新記錄用戶 NFT 持有 tokenId 列表的_owned mapping 結構，透過以下步驟完成：
            // _owned 專給 ERC721 用的狀態變量，是一個 mapping 結構，記錄某地址持有的所有 tokenId 陣列。
            // mapping(address => uint256[]) internal _owned;

            // Step2–1–8–1 : 取得 from 地址當前在 _owned mapping 記錄的 tokenId列表中的最後一個 tokenId，存於 updateId 區域變量。
            uint256 updatedId = _owned[from][_owned[from].length - 1];

            // 找到轉移的 tokenId 在 _owned index 位置換成最後一個 tokenId
            _owned[from][_ownedIndex[amountOrId]] = updatedId;
            // pop

            _owned[from].pop();
            // update index for the moved id
            _owned[to].push(amountOrId);
            // from 的 token id 移動因此改變 _ownedIndex 這個 tokenId 在一個的 _owned index 位置
            _ownedIndex[updatedId] = _ownedIndex[amountOrId];
            // push token to to owned，to 的 _owned 陣列新增轉移的 tokenId
            _owned[to].push(amountOrId);
            // update index for to owned，轉移的 tokenId 會在 to _owned 陣列的最後一個 index
            _ownedIndex[amountOrId] = _owned[to].length - 1;

            emit Transfer(from, to, amountOrId);
            emit ERC20Transfer(from, to, _getUnit());
        } else {
            // 取的 sender 的 allowance
            uint256 allowed = allowance[from][msg.sender];

            // type(uint256).max 是什麼？ 判斷 allowed 內容是否不等於 uint256 的上限。此判斷說明如果透過 approve 將 allowance 設為 uint256 上限，則可以免去這個減法運算，猜測是用來降低 gas fee 用的，意思即為永遠授權所有代幣的意思。
            if (allowed != type(uint256).max) {
                // 更新 allowance，轉移後 allowance 需要扣掉 轉移的量
                allowance[from][msg.sender] = allowed - amountOrId;
            }

            _transfer(from, to, amountOrId);
        }
    }

    /// @notice Function for fractional transfers
    // 這個 function 就是單純轉移 ERC20 代幣的 function。
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        // 直接呼叫_transfer internal function，主要用來執行真正的ERC20轉移行為，後面會詳細說明這邊的轉移邏輯。
        return _transfer(msg.sender, to, amount);
    }

    /// @notice Function for native transfers with contract support
    // 這個 function 基本上和 ERC721 的功能大同小異，就是轉移 NFT，但會檢查接收方是否是合約，如果是合約，會進一步檢查他是否實作 onERC721Received ，以證明他是可以接收 NFT 的合約
    function safeTransferFrom(address from, address to, uint256 id) public virtual {
        // transferFrom 會判斷是 tokenID 或是 amount，傳入 id 會轉移一顆的量
        transferFrom(from, to, id);

        // 確認 to 地址是否為合約、可以接收 NFT，call to 合約中是否實作 onERC721Received 且回傳值為ERC721Receiver.onERC721Received.selector
        if (
            to.code.length != 0
                && ERC721Receiver(to).onERC721Received(msg.sender, from, id, "") != ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    /// @notice Function for native transfers with contract support and callback data
    // 跟上一個差異是多了 calldata data，為什麼需要分兩個，而不是同一個鐘去判斷是否有 calldata？
    // calldata 的作用是什麼，這邊除了判斷好像沒有用到？
    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public virtual {
        transferFrom(from, to, id);

        if (
            to.code.length != 0
                && ERC721Receiver(to).onERC721Received(msg.sender, from, id, data)
                    != ERC721Receiver.onERC721Received.selector
        ) {
            revert UnsafeRecipient();
        }
    }

    // 這個 function 是上述 transfer, transferForm、safeTransferFrom 的底層轉移內部 function，執行實際的轉移邏輯，此 function 主要針對 ERC20 代幣的轉移。
    /// @notice Internal function for fractional transfers
    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        // 取得一顆 NFT 的量，也就是 ERC20 基本單位 (Ex: 10 ** 18)
        uint256 unit = _getUnit();
        // 取得 from 的 balance
        uint256 balanceBeforeSender = balanceOf[from];
        // 取得 to 的 balance
        uint256 balanceBeforeReceiver = balanceOf[to];

        balanceOf[from] -= amount;

        unchecked {
            balanceOf[to] += amount;
        }

        // Skip burn for certain addresses to save gas
        // 如果 from 沒有在 whitelist 代表可以同時使用 erc20 erc721
        // 設為白名單的地址，只涉及 ERC20 的操作，不涉及 NFT 的操作(burn & mint)
        if (!whitelist[from]) {
            // balanceBeforeSender 扣掉現在的 balance，tokens_to_burn 不是等於 amount? 為什麼要這樣做？因為有可能原本 balance 會多湊出一顆
            // 得出的數字為要燒掉多少 NFT，看原本有多少顆 NFT 扣掉現在有的 NFT 數量，這邊一定會是整數嗎？
            uint256 tokens_to_burn = (balanceBeforeSender / unit) - (balanceOf[from] / unit);

            // 跑一個 for 迴圈一個一個呼叫 _burn 這個 internal function，以燒掉 tokens_to_burn 要燒掉的數量
            for (uint256 i = 0; i < tokens_to_burn; i++) {
                _burn(from);
            }
        }

        // Skip minting for certain addresses to save gas
        // 計算 to 這邊要 mint 多少顆 NFT
        if (!whitelist[to]) {
            uint256 tokens_to_mint = (balanceOf[to] / unit) - (balanceBeforeReceiver / unit);
            for (uint256 i = 0; i < tokens_to_mint; i++) {
                _mint(to);
            }
        }

        emit ERC20Transfer(from, to, amount);
        return true;
    }

    // Internal utility logic
    // 直接回完傳一顆 ERC20 以最小單位計數的 amount。
    function _getUnit() internal view returns (uint256) {
        return 10 ** decimals;
    }

    // 此 function 主要是鑄造 NFT 的 function，主要是用來更改此合約的狀態變量，以表示NFT 被鑄造出來，鑄造方式為依序鑄造。
    function _mint(address to) internal virtual {
        // 檢查 from 是否為 0x00
        if (to == address(0)) {
            revert InvalidRecipient();
        }

        unchecked {
            // minted 表示目前 NFT Mint 到幾號。
            minted++;
        }

        // 目前 Mint 到幾號
        uint256 id = minted;

        // 檢查這個 NFT 是否已被擁有
        if (_ownerOf[id] != address(0)) {
            revert AlreadyExists();
        }

        // 更新這個 tokenId 紀錄：_ownerOf, _owned, _ownedIndex
        _ownerOf[id] = to;
        _owned[to].push(id);
        _ownedIndex[id] = _owned[to].length - 1;

        emit Transfer(address(0), to, id);
    }

    // 此 function 主要是燒毀 NFT 的 function，主要是用來更改此合約的狀態變量，以表示NFT 被燒毀，燒毀方式為燒毀 owned[ from ] 這個 list 中最後一個 tokenId 的 NFT。
    function _burn(address from) internal virtual {
        // 檢查 from 是否為 0x00
        if (from == address(0)) {
            revert InvalidSender();
        }

        // 取出 from  _owned 陣列最後一個 tokenId
        uint256 id = _owned[from][_owned[from].length - 1];
        // 移除 _owned 陣列最後一個 tokenId
        _owned[from].pop();
        // 移除這個 tokenId 的紀錄： _ownedIndex, _ownerOf, getApproved
        delete _ownedIndex[id];
        delete _ownerOf[id];
        delete getApproved[id];

        emit Transfer(from, address(0), id);
    }

    // 用於設定資產 name 與 symbol的function。
    function _setNameSymbol(string memory _name, string memory _symbol) internal {
        name = _name;
        symbol = _symbol;
    }
}
