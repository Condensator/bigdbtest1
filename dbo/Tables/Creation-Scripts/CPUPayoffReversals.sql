SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPUPayoffReversals](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[QuoteName] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[OtherReversalReasonInfo] [nvarchar](40) COLLATE Latin1_General_CI_AS NULL,
	[CPUPayoffId] [bigint] NOT NULL,
	[CPUContractId] [bigint] NOT NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[ReversalReasonId] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPUPayoffReversals]  WITH CHECK ADD  CONSTRAINT [ECPUPayoffReversal_CPUContract] FOREIGN KEY([CPUContractId])
REFERENCES [dbo].[CPUContracts] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffReversals] CHECK CONSTRAINT [ECPUPayoffReversal_CPUContract]
GO
ALTER TABLE [dbo].[CPUPayoffReversals]  WITH CHECK ADD  CONSTRAINT [ECPUPayoffReversal_CPUPayoff] FOREIGN KEY([CPUPayoffId])
REFERENCES [dbo].[CPUPayoffs] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffReversals] CHECK CONSTRAINT [ECPUPayoffReversal_CPUPayoff]
GO
ALTER TABLE [dbo].[CPUPayoffReversals]  WITH CHECK ADD  CONSTRAINT [ECPUPayoffReversal_ReversalReason] FOREIGN KEY([ReversalReasonId])
REFERENCES [dbo].[ContractAmendmentReasonCodes] ([Id])
GO
ALTER TABLE [dbo].[CPUPayoffReversals] CHECK CONSTRAINT [ECPUPayoffReversal_ReversalReason]
GO
