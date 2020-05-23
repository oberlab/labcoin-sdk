import 'dart:convert';

import 'package:http/http.dart';
import 'package:labcoin_sdk/labcoin_sdk.dart';

class LabcoinClient {
  LabcoinUri nodeAddress;

  LabcoinClient(this.nodeAddress);

  Future<List<Block>> _sendBlockchainRequest(String pathSegment) async {
    var response =
        await get('${nodeAddress.toString()}blockchain/$pathSegment');
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      var blocks = <Block>[];
      body.forEach((var trx) {
        blocks.add(Block.fromMap(trx));
      });
      return blocks;
    }
    return null;
  }

  void sendTransaction(BlockDataType transaction) =>
      post('${nodeAddress.toString()}transaction',
          body: jsonEncode(transaction.toMap()));

  void sendBlock(Block block) =>
      post('${nodeAddress.toString()}block', body: jsonEncode(block.toMap()));

  Future<List<Block>> getFullBlockchain() async => _sendBlockchainRequest('full');

  Future<List<Block>> getNewestBlocks(int length) async {
    if (!length.isNegative) {
      length *= -1;
    }
    var lengthString = length.toString();
    return _sendBlockchainRequest(lengthString);
  }

  Future<List<Block>> getOldestBlocks(int length) async {
    if (length.isNegative) {
      length *= -1;
    }
    var lengthString = length.toString();
    return _sendBlockchainRequest(lengthString);
  }

  Future<List<Transaction>> getMemPoolTransactions(String walletAddress) async {
    var response = await get('${nodeAddress.toString()}mempool/transactions');
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      var memPoolTransactions = <BlockDataType>[];
      body.forEach((var trx) {
        if (trx['type'] == Generic.TYPE) {
          memPoolTransactions.add(Generic.fromMap(trx));
        } else if (trx['type'] == Transaction.TYPE) {
          memPoolTransactions.add(Transaction.fromMap(trx));
        }
      });
      return memPoolTransactions;
    }
    return null;
  }

  Future<LabcoinAddress> getAddress(String walletAddress) async {
    var response = await get(
        '${nodeAddress.toString()}wallet/${Uri.encodeQueryComponent(walletAddress)}');
    if (response.statusCode == 200) {
      var body = jsonDecode(response.body);
      var funds = body['funds'] as int;
      var transactions = <Transaction>[];
      body['transactions'].forEach((var trx) {
        transactions.add(Transaction.fromMap(trx));
      });
      var memPoolTransactions = <Transaction>[];
      body['memPoolTransactions'].forEach((var trx) {
        memPoolTransactions.add(Transaction.fromMap(trx));
      });
      return LabcoinAddress(walletAddress, funds, transactions, memPoolTransactions);
    }
    return null;
  }
}
