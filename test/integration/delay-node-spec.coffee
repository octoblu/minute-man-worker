_          = require 'lodash'
Redis      = require 'ioredis'
RedisNS    = require '@octoblu/redis-ns'
mongojs    = require 'mongojs'
uuid       = require 'uuid'
Soldier    = require '../helpers/soldier'
Seconds    = require '../helpers/seconds'
PaulRevere = require '../../src/controllers/paul-revere'

describe 'Delay Node', ->
  beforeEach (done) ->
    @queueName = "seconds-#{uuid.v1()}"
    client = new Redis 'localhost', dropBufferSupport: true
    client.on 'ready', =>
      @client = new RedisNS 'test-worker', client
      @client.flushall done

  beforeEach (done) ->
    @database = mongojs 'minute-man-worker-test', ['soldiers']
    @database.dropDatabase (error) =>
      console.error error if error?
      done()

  beforeEach ->
    @seconds = new Seconds { @client, @queueName }
    @soldier = new Soldier { @database }
    @sut     = new PaulRevere { @database, @client, @queueName, offsetSeconds: 60 }

  describe 'when a delay of 30 seconds is set', ->
    beforeEach (done) ->
      @sut.getTime (error, @currentTimestamp) =>
        done error

    beforeEach (done) ->
      metadata = {
        intervalTime: 30000,
        processNow: true,
        processAt: _.clone(@currentTimestamp)
        fireOnce: true,
      }
      @soldier.create metadata, done

    beforeEach (done) ->
      @recordId = @soldier.getRecordId()
      @sut.findAndDeploySoldier @currentTimestamp, (error) =>
        return done error if error?
        @soldier.get done

    it 'should create have created only one second', (done) ->
      @seconds.hasOneSecond {@currentTimestamp,@recordId,intervalTime:30000}, done

    it 'should have an updated record', ->
      @soldier.checkUpdatedRecord({ @currentTimestamp })