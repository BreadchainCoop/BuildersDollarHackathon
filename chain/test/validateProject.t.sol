// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import 'forge-std/Test.sol';
import {MockEAS} from 'mocks/MockEAS.sol';
import 'contracts/ValidateProject.sol';

contract ProjectValidatorTest is Test {
  ProjectValidator private validator;
  MockEAS private mockEAS;
  address private optimismFoundation1 = address(0x123);
  address private optimismFoundation2 = address(0x456);

  uint256 private SEASON_DURATION = 1000;
  uint256 private currentSeasonExpiry = 2000;

  address[] private optimismFoundationAttestors;

  function setUp() public {
    mockEAS = new MockEAS();

    optimismFoundationAttestors = new address[](2);
    optimismFoundationAttestors[0] = optimismFoundation1;
    optimismFoundationAttestors[1] = optimismFoundation2;

    validator =
      new ProjectValidator(address(mockEAS), optimismFoundationAttestors, SEASON_DURATION, currentSeasonExpiry);
  }

  function testValidateProjectSuccess() public {
    bytes32 uid = keccak256(abi.encodePacked('test-attestation'));
    IEAS.Attestation memory attestation = IEAS.Attestation({
      uid: uid,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: 1500, // Within the season
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: optimismFoundation1,
      revocable: true,
      data: abi.encode('Grantee', 'param2', 'param3', 'param4', 'Application Approved')
    });
    mockEAS.setAttestation(uid, attestation);

    bool result = validator.validateProject(uid);
    assertTrue(result, 'Validation should return true');

    bool isEligible = validator.eligibleProjects(uid);
    assertTrue(isEligible, 'Project should be eligible');
  }

  function testValidateProjectAlreadyIncluded() public {
    bytes32 uid = keccak256(abi.encodePacked('test-attestation'));
    IEAS.Attestation memory attestation = IEAS.Attestation({
      uid: uid,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: 1500, // Within the season
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: optimismFoundation1,
      revocable: true,
      data: abi.encode('Grantee', 'param2', 'param3', 'param4', 'Application Approved')
    });
    mockEAS.setAttestation(uid, attestation);

    bool firstResult = validator.validateProject(uid);
    assertTrue(firstResult, 'First validation should return true');

    bool secondResult = validator.validateProject(uid);
    assertTrue(secondResult, 'Second validation should return true even if already included');

    bool isEligible = validator.eligibleProjects(uid);
    assertTrue(isEligible, 'Project should still be eligible');
  }

  function testValidateProjectInvalidAttester() public {
    bytes32 uid = keccak256(abi.encodePacked('test-attestation'));
    // Attester not in the list
    address invalidAttester = address(0x999);

    IEAS.Attestation memory attestation = IEAS.Attestation({
      uid: uid,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: 1500, // Within the season
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: invalidAttester,
      revocable: true,
      data: abi.encode('Grantee', 'param2', 'param3', 'param4', 'Application Approved')
    });
    mockEAS.setAttestation(uid, attestation);

    vm.expectRevert('Invalid attester');
    validator.validateProject(uid);
  }

  function testValidateProjectNotInCurrentSeason() public {
    uint256 seasonStartTime = currentSeasonExpiry - SEASON_DURATION;

    // Attestation before the season start
    bytes32 uidEarly = keccak256(abi.encodePacked('test-attestation-early'));
    IEAS.Attestation memory attestationEarly = IEAS.Attestation({
      uid: uidEarly,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: uint64(seasonStartTime - 1),
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: optimismFoundation1,
      revocable: true,
      data: abi.encode('Grantee', 'param2', 'param3', 'param4', 'Application Approved')
    });
    mockEAS.setAttestation(uidEarly, attestationEarly);

    vm.expectRevert('Attestation not in current season');
    validator.validateProject(uidEarly);

    // Attestation after the season end
    bytes32 uidLate = keccak256(abi.encodePacked('test-attestation-late'));
    IEAS.Attestation memory attestationLate = IEAS.Attestation({
      uid: uidLate,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: uint64(currentSeasonExpiry + 1),
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: optimismFoundation1,
      revocable: true,
      data: abi.encode('Grantee', 'param2', 'param3', 'param4', 'Application Approved')
    });
    mockEAS.setAttestation(uidLate, attestationLate);

    vm.expectRevert('Attestation not in current season');
    validator.validateProject(uidLate);
  }

  function testValidateProjectInvalidParam1() public {
    bytes32 uid = keccak256(abi.encodePacked('test-attestation'));
    IEAS.Attestation memory attestation = IEAS.Attestation({
      uid: uid,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: 1500, // Within the season
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: optimismFoundation1,
      revocable: true,
      data: abi.encode('Not Grantee', 'param2', 'param3', 'param4', 'Application Approved')
    });
    mockEAS.setAttestation(uid, attestation);

    vm.expectRevert('Invalid param1');
    validator.validateProject(uid);
  }

  function testValidateProjectInvalidParam5() public {
    bytes32 uid = keccak256(abi.encodePacked('test-attestation'));
    IEAS.Attestation memory attestation = IEAS.Attestation({
      uid: uid,
      schema: bytes32(0),
      refUID: bytes32(0),
      time: 1500, // Within the season
      expirationTime: 0,
      revocationTime: 0,
      recipient: address(0x789),
      attester: optimismFoundation1,
      revocable: true,
      data: abi.encode('Grantee', 'param2', 'param3', 'param4', 'Not Application Approved')
    });
    mockEAS.setAttestation(uid, attestation);

    vm.expectRevert('Invalid param5');
    validator.validateProject(uid);
  }
}
