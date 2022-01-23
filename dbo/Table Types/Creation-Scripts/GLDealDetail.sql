CREATE TYPE [dbo].[GLDealDetail] AS TABLE(
	[GLTransferComment] [nvarchar](500) COLLATE Latin1_General_CI_AS NULL,
	[NewAcquisitionId] [nvarchar](24) COLLATE Latin1_General_CI_AS NULL,
	[NewBQNBQ] [nvarchar](16) COLLATE Latin1_General_CI_AS NULL,
	[NewLegalEntityNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[NewLineofBusinessName] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[ContractSequenceNumber] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[RemitToUniqueIdentifier] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL
)
GO
