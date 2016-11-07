_            = require 'lodash'
{ ObjectId } = require 'mongojs'
debug        = require('debug')('minute-man-worker:soldiers')
overview     = require('debug')('minute-man-worker:soldiers:overview')

class Soldiers
  constructor: ({ database }) ->
    @collection = database.collection 'soldiers'

  get: ({ min, max }, callback) =>
    query = {
      'metadata.processing': { $ne: true }
      'metadata.processAt': { $lt: max }
    }
    update = { 'metadata.processing': true }
    sort = { 'metadata.processAt': 1 }
    debug 'get.query', JSON.stringify(query)
    debug 'get.update', update
    debug 'get.sort', sort
    @collection.findAndModify { query, update: { $set: update }, sort }, (error, record) =>
      return callback error if error?
      overview 'found record' if record?
      debug 'no record found' unless record?
      callback null, record

  update: ({ recordId, nextProcessAt, processAt }, callback) =>
    query  = { _id: new ObjectId(recordId) }
    update = {
      'metadata.processing': false
      'metadata.processAt': nextProcessAt
      'metadata.lastProcessAt': processAt
    }
    overview 'updating solider', { query, update }
    @collection.update query, { $set: update }, callback

  remove: ({ recordId }, callback) =>
    overview 'removing solider', { recordId }
    @collection.remove { _id: new ObjectId(recordId) }, callback

module.exports = Soldiers